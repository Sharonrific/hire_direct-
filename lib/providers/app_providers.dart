// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/models/job_model.dart';
import '../data/models/models.dart';
import '../data/services/auth_service.dart';
import '../data/services/job_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/review_service.dart';
import '../data/services/payment_service.dart';

// ── Services ──────────────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final jobServiceProvider = Provider<JobService>((ref) => JobService());
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());
final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

// ── Auth State ────────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authServiceProvider).getUserStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ── Jobs ──────────────────────────────────────────────────────────────────────
final allJobsProvider = StreamProvider.family<List<JobModel>, String?>((ref, category) {
  return ref.watch(jobServiceProvider).getJobsStream(
    category: category,
    status: 'Posted',
  );
});

final clientJobsProvider = StreamProvider.family<List<JobModel>, String>((ref, clientId) {
  return ref.watch(jobServiceProvider).getJobsStream(clientId: clientId);
});

final workerJobsProvider = StreamProvider.family<List<JobModel>, String>((ref, workerId) {
  return ref.watch(jobServiceProvider).getJobsStream(workerId: workerId);
});

final jobDetailProvider = StreamProvider.family<JobModel?, String>((ref, jobId) {
  return ref.watch(jobServiceProvider).getJobStream(jobId);
});

// ── Search ────────────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchCategoryProvider = StateProvider<String?>((ref) => null);
final searchMinBudgetProvider = StateProvider<double?>((ref) => null);
final searchMaxBudgetProvider = StateProvider<double?>((ref) => null);

final searchResultsProvider = FutureProvider<List<JobModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);
  final minBudget = ref.watch(searchMinBudgetProvider);
  final maxBudget = ref.watch(searchMaxBudgetProvider);
  return ref.watch(jobServiceProvider).searchJobs(
    query: query,
    category: category,
    minBudget: minBudget,
    maxBudget: maxBudget,
  );
});

// ── Chats ─────────────────────────────────────────────────────────────────────
final userChatsProvider = StreamProvider.family<List<ChatModel>, String>((ref, userId) {
  return ref.watch(chatServiceProvider).getUserChats(userId);
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatServiceProvider).getMessages(chatId);
});

// ── Reviews ───────────────────────────────────────────────────────────────────
final userReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, userId) {
  return ref.watch(reviewServiceProvider).getUserReviews(userId);
});

// ── Job Posting Form State ────────────────────────────────────────────────────
class JobPostingState {
  final String title;
  final String description;
  final String category;
  final double budget;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime? scheduledDate;
  final String scheduledTime;
  final String paymentType;
  final List<dynamic> images; // File or String (url)

  const JobPostingState({
    this.title = '',
    this.description = '',
    this.category = '',
    this.budget = 0,
    this.location = '',
    this.latitude,
    this.longitude,
    this.scheduledDate,
    this.scheduledTime = '',
    this.paymentType = 'escrow',
    this.images = const [],
  });

  JobPostingState copyWith({
    String? title, String? description, String? category, double? budget,
    String? location, double? latitude, double? longitude,
    DateTime? scheduledDate, String? scheduledTime, String? paymentType,
    List<dynamic>? images,
  }) {
    return JobPostingState(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      paymentType: paymentType ?? this.paymentType,
      images: images ?? this.images,
    );
  }
}

final jobPostingProvider = StateNotifierProvider<JobPostingNotifier, JobPostingState>(
  (ref) => JobPostingNotifier(),
);

class JobPostingNotifier extends StateNotifier<JobPostingState> {
  JobPostingNotifier() : super(const JobPostingState());

  void update(JobPostingState Function(JobPostingState) updater) {
    state = updater(state);
  }

  void reset() {
    state = const JobPostingState();
  }
}

// ── Selected Language for Chat ─────────────────────────────────────────────────
final chatLanguageProvider = StateProvider.family<String, String>((ref, chatId) => 'en');

// ── Bottom Nav Index ──────────────────────────────────────────────────────────
final clientNavIndexProvider = StateProvider<int>((ref) => 0);
final workerNavIndexProvider = StateProvider<int>((ref) => 0);
