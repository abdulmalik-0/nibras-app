import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/question_model.dart';

class QuestionView extends StatefulWidget {
  final QuestionModel question;

  const QuestionView({super.key, required this.question});

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  // Controllers for media players would go here (e.g., VideoPlayerController)
  // For simplicity in this step, we'll implement basic Image support and placeholders for Audio/Video
  // to avoid complex state management in this single file edit if possible, 
  // but for a real implementation we need state.
  
  // Let's implement Image first as it's stateless.
  // For Audio/Video, we'll add basic UI placeholders or simple implementations.
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.deepPurple.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Allow it to shrink if needed, but usually expanded
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: Colors.deepPurple.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'السؤال',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Media Content
          if (widget.question.mediaType == 'image' && widget.question.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: double.infinity,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.question.mediaUrl!.toLowerCase().endsWith('.svg')
                      ? SvgPicture.network(
                          widget.question.mediaUrl!,
                          height: 200,
                          fit: BoxFit.contain,
                          placeholderBuilder: (BuildContext context) => Container(
                            height: 200,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                        )
                      : Image.network(
                          widget.question.mediaUrl!,
                          height: 200,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                            );
                          },
                        ),
                ),
              ),
            ),

          if (widget.question.mediaType == 'audio')
             Padding(
               padding: const EdgeInsets.only(bottom: 20),
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.grey.shade300),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.audiotrack, color: Colors.deepPurple, size: 32),
                     const SizedBox(width: 16),
                     const Text('Audio Question (Coming Soon)', style: TextStyle(color: Colors.grey)),
                     // TODO: Implement Audio Player
                   ],
                 ),
               ),
             ),

          if (widget.question.mediaType == 'video')
             Padding(
               padding: const EdgeInsets.only(bottom: 20),
               child: AspectRatio(
                 aspectRatio: 16/9,
                 child: Container(
                   decoration: BoxDecoration(
                     color: Colors.black,
                     borderRadius: BorderRadius.circular(16),
                   ),
                   child: const Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                         SizedBox(height: 8),
                         Text('Video Question (Coming Soon)', style: TextStyle(color: Colors.white)),
                       ],
                     ),
                   ),
                   // TODO: Implement Video Player
                 ),
               ),
             ),

          Text(
            widget.question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
