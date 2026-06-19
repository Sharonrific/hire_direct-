// functions/index.js
// Firebase Cloud Functions — Stripe Payment Server
// Deploy with: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);

admin.initializeApp();
const db = admin.firestore();

/**
 * Create a Stripe PaymentIntent
 * Called by the Flutter app before presenting the payment sheet
 */
exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { amount, currency, description, customerId, metadata } = req.body;

    if (!amount || amount <= 0) {
      res.status(400).json({ error: 'Invalid amount' });
      return;
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount), // Already in cents from Flutter
      currency: currency || 'usd',
      description,
      automatic_payment_methods: { enabled: true },
      metadata: {
        ...metadata,
        userId: customerId,
      },
    });

    res.json({
      id: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      amount: paymentIntent.amount,
    });
  } catch (error) {
    console.error('Stripe error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Release escrow payment to worker
 * Called when client releases payment after job completion
 */
exports.releaseEscrow = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { jobId, paymentIntentId } = req.body;

    // Get job from Firestore to find worker's Stripe account
    const jobDoc = await db.collection('jobs').doc(jobId).get();
    if (!jobDoc.exists) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }

    const job = jobDoc.data();

    // Get worker's Stripe Connect account ID
    const workerDoc = await db.collection('users').doc(job.workerID).get();
    const worker = workerDoc.data();
    const workerStripeAccountId = worker?.stripeConnectAccountId;

    if (!workerStripeAccountId) {
      // Worker hasn't set up Stripe Connect yet — mark as pending payout
      await db.collection('jobs').doc(jobId).update({
        status: 'Payment Released',
        payoutPending: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      res.json({ success: true, message: 'Payment marked as released (worker payout pending Stripe setup)' });
      return;
    }

    // Transfer to worker's Stripe Connect account
    const transfer = await stripe.transfers.create({
      amount: Math.round((job.budget + job.totalAddOns) * 100),
      currency: 'usd',
      destination: workerStripeAccountId,
      transfer_group: jobId,
    });

    await db.collection('jobs').doc(jobId).update({
      status: 'Payment Released',
      stripeTransferId: transfer.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true, transferId: transfer.id });
  } catch (error) {
    console.error('Release escrow error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Handle no-show commitment fee logic
 * Called when a party marks the other as a no-show
 */
exports.processNoShow = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }

  try {
    const { jobId, noShowUserId, onTimeUserId } = req.body;

    // Transfer the no-show party's commitment fee to the on-time party
    // In production: look up their Stripe accounts and transfer $20

    await db.collection('jobs').doc(jobId).update({
      noShowProcessed: true,
      noShowUserId,
      onTimeUserId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
