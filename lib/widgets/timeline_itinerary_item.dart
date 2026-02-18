import 'package:flutter/material.dart';
import '../models/trip_plan.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TimelineItineraryItem extends StatelessWidget {
  final TripPlanPlace place;
  final int index;
  final bool isLast;
  final bool canEdit;
  final VoidCallback onTap;

  const TimelineItineraryItem({
    super.key,
    required this.place,
    required this.index,
    required this.isLast,
    required this.canEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline vertical line and dot
              Column(
                children: [
                   Container(
                     width: 12,
                     height: 12,
                     decoration: BoxDecoration(
                       color: Colors.blue.shade600,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.white, width: 2),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.blue.withOpacity(0.3),
                           blurRadius: 4,
                           spreadRadius: 1,
                         ),
                       ],
                     ),
                   ),
                   if (!isLast)
                     Expanded(
                       child: Container(
                         width: 2,
                         color: Colors.blue.shade100,
                       ),
                     ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Place content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          place.arrivalTime ?? "09:00",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (place.rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 10, color: Colors.amber.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  "${place.rating}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                place.type,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: place.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: place.imageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 20),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade100,
                                  child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 20),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isLast)
                      const SizedBox(height: 8),
                  ],
                ),
              ),
              
              if (canEdit)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
