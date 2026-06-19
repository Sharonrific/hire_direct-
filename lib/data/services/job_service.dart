// lib/data/services/job_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/job_model.dart';
import '../../core/constants/app_constants.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<JobModel> createJob({
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    required String title,
    required String description,
    required String category,
    required double budget,
    required String location,
    double? latitude,
    double? longitude,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String paymentType,
    required List<File> images,
  }) async {
    final jobId = _uuid.v4();

    // Upload images
    final imageUrls = await _uploadJobImages(jobId, images);

    final job = JobModel(
      id: jobId,
      clientId: clientId,
      clientName: clientName,
      clientPhotoUrl: clientPhotoUrl,
      title: title,
      description: description,
      category: category,
      budget: budget,
      location: location,
      latitude: latitude,
      longitude: longitude,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      paymentType: paymentType,
      imageUrls: imageUrls,
      status: AppConstants.statusPosted,
      createdAt: DateTime.now(),
      appearsInGeneralLabor: true,
    );

    await _firestore
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .set(job.toMap());

    return job;
  }

  Future<List<String>> _uploadJobImages(String jobId, List<File> images) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final ref = _storage.ref('jobs/$jobId/image_$i.jpg');
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadSingleImage(String path, File file) async {
    final ref = _storage.ref(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Stream<List<JobModel>> getJobsStream({
    String? category,
    String? status,
    String? clientId,
    String? workerId,
  }) {
    Query query = _firestore.collection(AppConstants.jobsCollection);

    if (category != null && category != 'All') {
      if (category == 'General Labor') {
        query = query.where('appearsInGeneralLabor', isEqualTo: true);
      } else {
        query = query.where('category', isEqualTo: category);
      }
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }
    if (workerId != null) {
      query = query.where('workerID', isEqualTo: workerId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<JobModel?> getJobById(String jobId) async {
    final doc = await _firestore
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .get();
    if (doc.exists) return JobModel.fromMap(doc.data()!);
    return null;
  }

  Stream<JobModel?> getJobStream(String jobId) {
    return _firestore
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .snapshots()
        .map((doc) => doc.exists ? JobModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> assignWorker(String jobId, String workerId,
      String workerName, String? workerPhotoUrl) async {
    await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
      'workerID': workerId,
      'workerName': workerName,
      'workerPhotoUrl': workerPhotoUrl,
      'status': AppConstants.statusBooked,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> addAddOn(String jobId, AddOnModel addOn) async {
    final doc = await _firestore
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .get();
    final job = JobModel.fromMap(doc.data()!);
    final updatedAddOns = [...job.addOns, addOn];
    await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
      'addOns': updatedAddOns.map((a) => a.toMap()).toList(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateAddOnStatus(String jobId, String addOnId, String status,
      {String? paymentIntentId}) async {
    final doc = await _firestore
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .get();
    final job = JobModel.fromMap(doc.data()!);
    final updatedAddOns = job.addOns.map((a) {
      if (a.id == addOnId) {
        return AddOnModel(
          id: a.id, jobId: a.jobId, workerId: a.workerId,
          description: a.description, price: a.price,
          status: status, createdAt: a.createdAt,
          stripePaymentIntentId: paymentIntentId ?? a.stripePaymentIntentId,
        );
      }
      return a;
    }).toList();
    await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
      'addOns': updatedAddOns.map((a) => a.toMap()).toList(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<JobModel>> searchJobs({
    String? query,
    String? category,
    double? minBudget,
    double? maxBudget,
    double? minRating,
  }) async {
    Query q = _firestore.collection(AppConstants.jobsCollection)
        .where('status', isEqualTo: AppConstants.statusPosted);

    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    if (minBudget != null) {
      q = q.where('budget', isGreaterThanOrEqualTo: minBudget);
    }
    if (maxBudget != null) {
      q = q.where('budget', isLessThanOrEqualTo: maxBudget);
    }

    final snap = await q.orderBy('createdAt', descending: true).get();
    var jobs = snap.docs
        .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>))
        .toList();

    if (query != null && query.isNotEmpty) {
      final lq = query.toLowerCase();
      jobs = jobs.where((j) =>
        j.title.toLowerCase().contains(lq) ||
        j.description.toLowerCase().contains(lq) ||
        j.category.toLowerCase().contains(lq)
      ).toList();
    }

    return jobs;
  }

  Future<void> releaseEscrowPayment(String jobId) async {
    await _firestore.collection(AppConstants.jobsCollection).doc(jobId).update({
      'status': AppConstants.statusPaymentReleased,
      'updatedAt': Timestamp.now(),
    });
  }
}
