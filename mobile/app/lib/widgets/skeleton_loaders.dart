import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Base skeleton widget with shimmer effect
class SkeletonWidget extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonWidget({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark 
          ? Colors.grey.shade800 
          : Colors.grey.shade300,
      highlightColor: isDark 
          ? Colors.grey.shade700 
          : Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Account card skeleton
class AccountCardSkeleton extends StatelessWidget {
  const AccountCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonWidget(
                  height: 40,
                  width: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(height: 16, width: 120),
                      const SizedBox(height: 4),
                      const SkeletonWidget(height: 12, width: 80),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerRight,
              child: SkeletonWidget(height: 24, width: 100),
            ),
          ],
        ),
      ),
    );
  }
}

// Transaction item skeleton
class TransactionItemSkeleton extends StatelessWidget {
  const TransactionItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SkeletonWidget(
            height: 48,
            width: 48,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonWidget(height: 16, width: 150),
                const SizedBox(height: 4),
                const SkeletonWidget(height: 12, width: 100),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SkeletonWidget(height: 16, width: 60),
              const SizedBox(height: 4),
              const SkeletonWidget(height: 12, width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

// Transaction list skeleton
class TransactionListSkeleton extends StatelessWidget {
  final int itemCount;

  const TransactionListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const TransactionItemSkeleton(),
    );
  }
}

// Dashboard skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance card skeleton
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonWidget(height: 16, width: 100),
                  const SizedBox(height: 8),
                  const SkeletonWidget(height: 32, width: 180),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonWidget(height: 12, width: 60),
                            const SizedBox(height: 4),
                            const SkeletonWidget(height: 20, width: 100),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonWidget(height: 12, width: 60),
                            const SizedBox(height: 4),
                            const SkeletonWidget(height: 20, width: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Quick actions skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonWidget(height: 16, width: 100),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonWidget(
                        height: 40,
                        width: 40,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(height: 8),
                      const SkeletonWidget(height: 12, width: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Recent transactions skeleton
          const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonWidget(height: 16, width: 150),
          ),
          const TransactionListSkeleton(),
        ],
      ),
    );
  }
}

// Card skeleton for cards screen
class CardItemSkeleton extends StatelessWidget {
  const CardItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonWidget(height: 24, width: 80),
                  SkeletonWidget(
                    height: 40,
                    width: 60,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SkeletonWidget(height: 20, width: 200),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(height: 12, width: 60),
                      const SizedBox(height: 4),
                      const SkeletonWidget(height: 14, width: 100),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SkeletonWidget(height: 12, width: 40),
                      const SizedBox(height: 4),
                      const SkeletonWidget(height: 14, width: 50),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Analytics skeleton
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonWidget(height: 14, width: 80),
                        const SizedBox(height: 8),
                        const SkeletonWidget(height: 24, width: 100),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonWidget(height: 14, width: 80),
                        const SizedBox(height: 8),
                        const SkeletonWidget(height: 24, width: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Chart skeleton
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonWidget(height: 16, width: 150),
                  const SizedBox(height: 16),
                  const SkeletonWidget(height: 200),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonWidget(height: 16, width: 150),
                  const SizedBox(height: 16),
                  ...List.generate(5, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SkeletonWidget(
                          height: 40,
                          width: 40,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: SkeletonWidget(height: 16, width: 100),
                        ),
                        const SkeletonWidget(height: 16, width: 60),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated skeleton container for custom shapes
class AnimatedSkeletonContainer extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const AnimatedSkeletonContainer({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? SkeletonWidget(
              height: 100,
              borderRadius: BorderRadius.circular(12),
            )
          : child,
    );
  }
}