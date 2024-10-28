import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';

class TaskOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  final Map<String, dynamic>? projectData;

  const TaskOverviewScreen({
    super.key,
    required this.taskData,
    this.projectData,
  });

  @override
  State<TaskOverviewScreen> createState() => _TaskOverviewScreenState();
}

class _TaskOverviewScreenState extends State<TaskOverviewScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _currentStatus = 'todo';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.taskData['status'] ?? 'todo';
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

  void _updateTaskStatus(String newStatus) async {
    try {
      // Get the project and task IDs from the data passed to the screen
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

  Widget _buildStatusButton(String status, ThemeData theme) {
    bool isSelected = _currentStatus == status;
    Color statusColor;
    switch (status) {
      case 'todo':
        statusColor = const Color(0xFFF6BB54);
        break;
      case 'in_progress':
        statusColor = const Color(0xFF9D9BFF);
        break;
      case 'completed':
        statusColor = const Color(0xFF5CD669);
        break;
      default:
        statusColor = Colors.grey;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? statusColor : theme.colorScheme.surface,
            foregroundColor: isSelected ? Colors.white : statusColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0, // Remove shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _updateTaskStatus(status),
          child: Text(
            _formatStatus(status),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample data for the progress chart
    final List<FlSpot> progressSpots = [
      const FlSpot(12, 0.45),
      const FlSpot(13, 0.53),
      const FlSpot(14, 0.58),
      const FlSpot(15, 0.48),
      const FlSpot(16, 0.56),
      const FlSpot(17, 0.65),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.taskData['title'] ?? 'Task Details',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            onPressed: () {
              // Add more options menu here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Status Buttons
              Row(
                children: [
                  _buildStatusButton('todo', theme),
                  _buildStatusButton('in_progress', theme),
                  _buildStatusButton('completed', theme),
                ],
              ),

              const SizedBox(height: 24),

              // Task Progress Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
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
                    Text(
                      'Task Progress',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${(value * 100).toInt()}%',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: progressSpots,
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: theme.colorScheme.primary,
                                    strokeWidth: 2,
                                    strokeColor: theme.colorScheme.surface,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Task Timeline Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
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
                    Text(
                      'Task Timeline',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTimelineItem('Interview', const Color(0xFFF6BB54), '12-13'),
                    _buildTimelineItem('Ideate', const Color(0xFF5CD669), '13-15'),
                    _buildTimelineItem('Wireframe', const Color(0xFF9D9BFF), '15-17'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Task Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
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
                    Text(
                      'Task Details',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'Project',
                      widget.projectData?['name'] ?? 'Unknown Project',
                      Icons.folder_outlined,
                      theme,
                    ),
                    _buildDetailItem(
                      'Created By',
                      widget.taskData['createdBy'] ?? 'Unknown',
                      Icons.person_outline,
                      theme,
                    ),
                    _buildDetailItem(
                      'Assigned To',
                      widget.taskData['assignedTo'] ?? 'Unassigned',
                      Icons.assignment_ind_outlined,
                      theme,
                    ),
                    _buildDetailItem(
                      'Description',
                      widget.taskData['description'] ?? 'No description available',
                      Icons.description_outlined,
                      theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, Color color, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: color.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}