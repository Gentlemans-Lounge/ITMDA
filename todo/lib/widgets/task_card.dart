import 'package:flutter/material.dart';
import 'dart:math';
import '../services/firebase_service.dart';

class TaskCard extends StatefulWidget {
  final ThemeData theme;
  final Map<String, dynamic> taskData;
  final Map<String, dynamic>? projectData;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.theme,
    required this.taskData,
    this.projectData,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final FirebaseService _firebaseService = FirebaseService();
  final Random _random = Random();
  late double _progress;
  late String _currentStatus;
  bool _showStatusOptions = false;

  @override
  void initState() {
    super.initState();
    _progress = _random.nextDouble() * 100;
    _currentStatus = widget.taskData['status'] ?? 'todo';
  }

  // Add this method
  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update current status when new data comes in
    if (widget.taskData['status'] != oldWidget.taskData['status']) {
      setState(() {
        _currentStatus = widget.taskData['status'] ?? 'todo';
      });
    }
  }

  void _updateTaskStatus(String newStatus) async {

    try {
      final String? projectId = widget.taskData['projectId'];
      final String? taskId = widget.taskData['taskId'];


      if (projectId == null || taskId == null) {
        throw Exception('Task or Project ID is missing');
      }

      await _firebaseService.updateTaskStatus(
        projectId,
        taskId,
        newStatus,
      );

      setState(() {
        _currentStatus = newStatus;
        _showStatusOptions = false;
      });


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: const Color(0xFF5CD669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
        return const Color(0xFFF6BB54);
      case 'in_progress':
        return const Color(0xFF9D9BFF);
      case 'completed':
        return const Color(0xFF5CD669);
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      default:
        return status.split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  Widget _buildStatusPill() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showStatusOptions = !_showStatusOptions;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(_currentStatus).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatStatus(_currentStatus),
              style: TextStyle(
                color: _getStatusColor(_currentStatus),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_showStatusOptions)
              const SizedBox(width: 4),
            if (_showStatusOptions)
              Icon(
                Icons.keyboard_arrow_up,
                size: 16,
                color: _getStatusColor(_currentStatus),
              )
            else
              const SizedBox(width: 4),
            if (!_showStatusOptions)
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: _getStatusColor(_currentStatus),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOptions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 150,
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusOption('todo'),
          const Divider(height: 1),
          _buildStatusOption('in_progress'),
          const Divider(height: 1),
          _buildStatusOption('completed'),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status) {
    return InkWell(
      onTap: () => _updateTaskStatus(status),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatStatus(status),
              style: TextStyle(
                color: widget.theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentStatus == status)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: _getStatusColor(status),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.taskData['title'] ?? 'Untitled Task',
                        style: TextStyle(
                          color: widget.theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusPill(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.taskData['description'] ?? 'No description available',
                  style: TextStyle(
                    color: widget.theme.colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Progress Bar and Percentage
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress / 100,
                          backgroundColor: widget.theme.colorScheme.onSurface.withOpacity(0.1),
                          color: _getStatusColor(_currentStatus),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getStatusColor(_currentStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (widget.projectData != null)
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: widget.theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.projectData?['name'] ?? 'Unknown Project',
                        style: TextStyle(
                          color: widget.theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_showStatusOptions)
          Positioned(
            top: 40,
            right: 0,
            child: _buildStatusOptions(),
          ),
      ],
    );
  }
}