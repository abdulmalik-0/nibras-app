import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../models/question_model.dart';
import 'edit_question_page.dart';
import 'package:intl/intl.dart' as intl;

class ReportedQuestionsPage extends StatefulWidget {
  const ReportedQuestionsPage({super.key});

  @override
  State<ReportedQuestionsPage> createState() => _ReportedQuestionsPageState();
}

class _ReportedQuestionsPageState extends State<ReportedQuestionsPage> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  final _authService = AuthService();
  late TabController _tabController;
  
  Map<String, List<QuestionModel>> _questionsByStatus = {
    'pending': [],
    'valid': [],
    'invalid': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportedQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportedQuestions() async {
    setState(() => _isLoading = true);
    
    final pending = await _supabaseService.getReportedQuestionsByStatus('pending');
    final valid = await _supabaseService.getReportedQuestionsByStatus('valid');
    final invalid = await _supabaseService.getReportedQuestionsByStatus('invalid');
    
    setState(() {
      _questionsByStatus = {
        'pending': pending,
        'valid': valid,
        'invalid': invalid,
      };
      _isLoading = false;
    });
  }

  Future<void> _resolveReport(QuestionModel question, String userId, bool isValid) async {
    if (isValid) {
      // For valid reports, open edit page
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EditQuestionPage(
            question: question,
            reportUserId: userId,
          ),
        ),
      );

      // If edit was successful, reload
      if (result == true) {
        await _loadReportedQuestions();
      }
    } else {
      // For invalid reports, resolve directly
      try {
        final adminId = _authService.currentUser?.id ?? '';
        await _supabaseService.resolveReport(question.id, userId, false, adminId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل البلاغ كغير صحيح'),
            backgroundColor: Colors.orange,
          ),
        );
        
        await _loadReportedQuestions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _deleteReport(String questionId, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا البلاغ؟ لن يتم تسجيله على المستخدم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteReport(questionId, userId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف البلاغ'),
            backgroundColor: Colors.red,
          ),
        );
        
        await _loadReportedQuestions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _deleteQuestionReports(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جميع البلاغات'),
        content: const Text('هل أنت متأكد من حذف جميع البلاغات لهذا السؤال؟ سيتم تصفير عداد البلاغات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف الجميع'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteQuestionReports(questionId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف جميع البلاغات'),
            backgroundColor: Colors.red,
          ),
        );
        
        await _loadReportedQuestions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _showMediaDialog(QuestionModel question) {
    if (question.mediaUrl == null || question.mediaUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      question.mediaType == 'image'
                          ? 'الصورة'
                          : question.mediaType == 'video'
                              ? 'الفيديو'
                              : 'الصوت',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Media Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (question.mediaType == 'image') ...[
                          Image.network(
                            question.mediaUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.amber,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Column(
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'فشل تحميل الصورة',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'استخدم الرابط أدناه لفتحها في المتصفح',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          Icon(
                            question.mediaType == 'video'
                                ? Icons.video_library
                                : Icons.audiotrack,
                            size: 64,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // URL Section (for all media types)
                        Text(
                          question.mediaType == 'image'
                              ? 'رابط الصورة:'
                              : question.mediaType == 'video'
                                  ? 'رابط الفيديو:'
                                  : 'رابط الصوت:',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            question.mediaUrl!,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: question.mediaUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ الرابط')),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('نسخ الرابط'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البلاغات'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'قيد المراجعة'),
            Tab(text: 'صحيحة'),
            Tab(text: 'غير صحيحة'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade600,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionList('pending'),
                  _buildQuestionList('valid'),
                  _buildQuestionList('invalid'),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionList(String status) {
    final questions = _questionsByStatus[status] ?? [];
    
    if (questions.isEmpty) {
      return Center(
        child: Text(
          status == 'pending' 
              ? 'لا توجد بلاغات قيد المراجعة'
              : status == 'valid'
                  ? 'لا توجد بلاغات صحيحة'
                  : 'لا توجد بلاغات غير صحيحة',
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(question, status);
      },
    );
  }

  Widget _buildQuestionCard(QuestionModel question, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.amber,
          title: Text(
            question.question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${question.id}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'عدد البلاغات: ${question.reportCount}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteQuestionReports(question.id),
                    icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'حذف الكل', 
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
              if (question.mediaUrl != null && question.mediaUrl!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      question.mediaType == 'image'
                          ? Icons.image
                          : question.mediaType == 'video'
                              ? Icons.video_library
                              : Icons.audiotrack,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      question.mediaType == 'image'
                          ? 'يحتوي على صورة'
                          : question.mediaType == 'video'
                              ? 'يحتوي على فيديو'
                              : 'يحتوي على صوت',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: question.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ رقم السؤال (ID)')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18, color: Colors.amber),
                    label: const Text('نسخ ID', style: TextStyle(color: Colors.amber)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: question.question));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ نص السؤال')),
                      );
                    },
                    icon: const Icon(Icons.copy_all, size: 18, color: Colors.amber),
                    label: const Text('نسخ السؤال', style: TextStyle(color: Colors.amber)),
                  ),
                  if (question.mediaUrl != null && question.mediaUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showMediaDialog(question),
                      icon: const Icon(Icons.play_circle, size: 18, color: Colors.green),
                      label: const Text('عرض الوسائط', style: TextStyle(color: Colors.green)),
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.1)),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _supabaseService.getQuestionReports(question.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('لا توجد تفاصيل', style: TextStyle(color: Colors.white70)),
                  );
                }
                
                // Filter reports by status
                final allReports = snapshot.data!;
                final filteredReports = allReports.where((report) {
                  final reportStatus = report['status'] as String?;
                  if (status == 'pending') {
                    return reportStatus == null || reportStatus == 'pending';
                  }
                  return reportStatus == status;
                }).toList();

                if (filteredReports.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('لا توجد بلاغات بهذه الحالة', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, reportIndex) {
                    final report = filteredReports[reportIndex];
                    return _buildReportItem(report, question, status);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report, QuestionModel question, String status) {
    final timestamp = report['created_at'] != null
        ? DateTime.parse(report['created_at'])
        : DateTime.now();
    final resolvedAt = report['resolved_at'] != null
        ? DateTime.parse(report['resolved_at'])
        : null;
    final userId = report['user_id'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info & Delete Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple.shade300,
                child: Text(
                  (report['username'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['username'] ?? 'مجهول',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      report['email'] ?? 'لا يوجد بريد',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              if (status == 'pending' && userId != null)
                IconButton(
                  onPressed: () => _deleteReport(question.id, userId),
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  tooltip: 'حذف البلاغ',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reason Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سبب البلاغ:',
                  style: TextStyle(color: Colors.amber.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  report['reason'] ?? 'لا يوجد سبب',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Actions Row (Copy & Date)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: report['reason'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ نص البلاغ')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16, color: Colors.blueAccent),
                label: const Text('نسخ النص', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                intl.DateFormat('yyyy/MM/dd - hh:mm a').format(timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),

          if (resolvedAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'تم الحل: ${intl.DateFormat('yyyy/MM/dd').format(resolvedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.green.shade300),
              ),
            ),
          ],

          // Action Buttons (Valid/Invalid)
          if (status == 'pending' && userId != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveReport(question, userId, true),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('بلاغ صحيح'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveReport(question, userId, false),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('غير صحيح'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
