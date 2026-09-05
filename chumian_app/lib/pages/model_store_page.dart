import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/local_model.dart';
import '../providers/model_store_provider.dart';

class ModelStorePage extends StatefulWidget {
  const ModelStorePage({super.key});

  @override
  State<ModelStorePage> createState() => _ModelStorePageState();
}

class _ModelStorePageState extends State<ModelStorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_CategoryTab> _categories = [
    _CategoryTab(label: '推荐', value: 'recommended', icon: Icons.star),
    _CategoryTab(label: '全部', value: 'all', icon: Icons.grid_view),
    _CategoryTab(label: '语言', value: 'language', icon: Icons.chat),
    _CategoryTab(label: '视频', value: 'video', icon: Icons.videocam),
    _CategoryTab(label: '图像', value: 'image', icon: Icons.image),
    _CategoryTab(label: '音频', value: 'audio', icon: Icons.mic),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModelStoreProvider>(context, listen: false).fetchModels();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('模型商店', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink500)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.pink500,
          unselectedLabelColor: AppColors.pink300,
          indicatorColor: AppColors.pink500,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          onTap: (index) {
            Provider.of<ModelStoreProvider>(context, listen: false)
                .setCategory(_categories[index].value);
          },
          tabs: _categories
              .map((c) => Tab(icon: Icon(c.icon, size: 18), text: c.label))
              .toList(),
        ),
      ),
      body: Consumer<ModelStoreProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pink500),
            );
          }
          return RefreshIndicator(
            color: AppColors.pink500,
            onRefresh: () => provider.fetchModels(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.filteredModels.length,
              itemBuilder: (context, index) {
                final model = provider.filteredModels[index];
                return _ModelCard(model: model, index: index);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTab {
  final String label;
  final String value;
  final IconData icon;
  const _CategoryTab({required this.label, required this.value, required this.icon});
}

class _ModelCard extends StatefulWidget {
  final LocalModel model;
  final int index;
  const _ModelCard({required this.model, required this.index});

  @override
  State<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<_ModelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + widget.index * 50),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ModelStoreProvider>(context, listen: false);
    final model = widget.model;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink200.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: model.recommended
                ? Border.all(color: AppColors.pink300, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.pink300, AppColors.pink500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(model.typeIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                model.name,
                                style: AppTextStyles.title.copyWith(
                                  color: AppColors.pink500,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (model.recommended)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.pink500,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '推荐',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(model.typeLabel),
                            const SizedBox(width: 6),
                            _buildTag(model.params),
                            const SizedBox(width: 6),
                            _buildTag(model.sizeDisplay),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                model.description,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (model.downloadStatus == 'downloading')
                _buildDownloadProgress(model)
              else
                _buildActionButton(model, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.pink50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: AppColors.pink400),
      ),
    );
  }

  Widget _buildDownloadProgress(LocalModel model) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: model.downloadProgress,
            backgroundColor: AppColors.pink100,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.pink500),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(model.downloadProgress * 100).toStringAsFixed(1)}%  '
              '${model.downloadSpeed.toStringAsFixed(1)} MB/s',
              style: AppTextStyles.caption.copyWith(color: AppColors.pink500),
            ),
            Text(
              '${(model.downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${model.sizeDisplay}',
              style: AppTextStyles.caption.copyWith(color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Provider.of<ModelStoreProvider>(context, listen: false).pauseDownload(model),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pink500,
                  side: BorderSide(color: AppColors.pink300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('暂停'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Provider.of<ModelStoreProvider>(context, listen: false).cancelDownload(model),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(LocalModel model, ModelStoreProvider provider) {
    if (model.isDownloaded) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.pink50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pink200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.pink500, size: 20),
                  const SizedBox(width: 8),
                  Text('已下载', style: TextStyle(color: AppColors.pink500, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showDeleteConfirm(model, provider),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      );
    }

    if (model.downloadStatus == 'paused') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => provider.downloadModel(model),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pink500,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('继续下载'),
        ),
      );
    }

    if (model.downloadStatus == 'error') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => provider.downloadModel(model),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('重试下载'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => provider.downloadModel(model),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
        ),
        icon: const Icon(Icons.download, size: 20),
        label: Text('下载模型 (${model.sizeDisplay})'),
      ),
    );
  }

  void _showDeleteConfirm(LocalModel model, ModelStoreProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除模型', style: AppTextStyles.title),
        content: Text('确定要删除「${model.name}」吗？删除后需要重新下载才能使用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: AppColors.pink400)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteModel(model);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
