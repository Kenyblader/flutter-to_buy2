import 'package:flutter/material.dart';

class RecordButton extends StatefulWidget {
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;
  final bool isRecording;

  const RecordButton({
    Key? key,
    required this.onRecordStart,
    required this.onRecordStop,
    this.isRecording = false,
  }) : super(key: key);

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour l'état local si l'état externe change
    if (widget.isRecording != _isRecording) {
      setState(() {
        _isRecording = widget.isRecording;
      });

      if (_isRecording) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _animationController.forward();
      widget.onRecordStart();
    } else {
      _animationController.reverse();
      widget.onRecordStop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isRecording ? 80.0 : 70.0,
        height: _isRecording ? 80.0 : 70.0,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _animationController,
            size: 36,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
