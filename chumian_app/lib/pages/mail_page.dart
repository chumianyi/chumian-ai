import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/mail_agent_post.dart';

class MailPage extends StatefulWidget {
  const MailPage({super.key});
  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> with TickerProviderStateMixin {
  List<MailItem> _mails = [];
  bool _loading = true;
  MailItem? _selectedMail;
  String? _mailContent;

  // Pull-out animation
  late AnimationController _pullCtrl;
  late Animation<double> _pullUpAnim;
  late Animation<double> _pullScaleAnim;
  late AnimationController _openCtrl;
  late Animation<double> _openHeightAnim;
  late Animation<double> _openFadeAnim;
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _pullCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pullUpAnim = Tween<double>(begin: 0, end: -60).animate(CurvedAnimation(parent: _pullCtrl, curve: Curves.easeOutCubic));
    _pullScaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pullCtrl, curve: Curves.easeOut));
    _openCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _openHeightAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _openCtrl, curve: Curves.easeOutCubic));
    _openFadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _openCtrl, curve: const Interval(0.3, 1.0)));
    _loadMails();
  }

  @override
  void dispose() {
    _pullCtrl.dispose();
    _openCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMails() async {
    try {
      final mails = await ApiService().getMails();
      setState(() => _mails = mails);
    } catch (e) {
      // Fallback: show welcome mail if API fails
      setState(() => _mails = [MailItem(id: 'welcome', sender: '初眠AI官方', title: '欢迎加入初眠AI！', content: '欢迎使用初眠AI！', isRead: false)]);
    }
    setState(() => _loading = false);
  }

  Future<void> _openMail(MailItem mail) async {
    setState(() => _selectedMail = mail);
    _pullCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final detail = await ApiService().getMailDetail(mail.id);
      _mailContent = detail.content;
      setState(() {
        final idx = _mails.indexWhere((m) => m.id == mail.id);
        if (idx >= 0) _mails[idx] = MailItem(id: mail.id, sender: mail.sender, title: mail.title, content: detail.content, isRead: true, createdAt: mail.createdAt);
      });
    } catch (_) {
      _mailContent = mail.content;
    }
    _openCtrl.forward();
    setState(() => _showDetail = true);
  }

  Future<void> _closeMail() async {
    await _openCtrl.reverse();
    await _pullCtrl.reverse();
    setState(() { _showDetail = false; _selectedMail = null; _mailContent = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: _showDetail ? IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.primaryDeep), onPressed: _closeMail) : null,
        title: Text(_showDetail ? '信件详情' : '我的信件', style: const TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai')),
        actions: [if (!_showDetail) IconButton(icon: const Icon(Icons.mark_email_read, color: AppColors.textSecondary), onPressed: () async { await ApiService().markAllMailsRead(); _loadMails(); })],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _showDetail ? _buildDetailView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    if (_mails.isEmpty) return const Center(child: Text('暂无信件', style: TextStyle(color: AppColors.textHint, fontFamily: 'LXGW WenKai')));
    return RefreshIndicator(
      onRefresh: _loadMails,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mails.length,
        itemBuilder: (_, i) {
          final mail = _mails[i];
          final isSelected = _selectedMail?.id == mail.id;
          return AnimatedBuilder(
            animation: _pullCtrl,
            builder: (context, child) {
              final offset = isSelected ? _pullUpAnim.value : 0.0;
              final scale = isSelected ? _pullScaleAnim.value : 1.0;
              return Transform.translate(
                offset: Offset(0, offset),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: _buildMailCard(mail, i),
          );
        },
      ),
    );
  }

  Widget _buildMailCard(MailItem mail, int index) {
    return GestureDetector(
      onTap: () => _openMail(mail),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: mail.isRead ? Colors.white : AppColors.surfacePink,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mail.isRead ? AppColors.borderLight : AppColors.primary.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: mail.isRead ? Colors.transparent : AppColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(mail.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai'))),
              Text('${mail.createdAt.month}/${mail.createdAt.day} ${mail.createdAt.hour}:${mail.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
            ]),
            const SizedBox(height: 4),
            Text(mail.sender, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500, fontFamily: 'LXGW WenKai')),
            const SizedBox(height: 2),
            Text(mail.content.isEmpty ? '点击查看详情' : mail.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
          ])),
        ]),
      ),
    );
  }

  Widget _buildDetailView() {
    if (_selectedMail == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _openCtrl,
        builder: (context, child) {
          return SizeTransition(
            sizeFactor: _openHeightAnim,
            axisAlignment: -1,
            child: FadeTransition(opacity: _openFadeAnim, child: child),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 16)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_selectedMail!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
            const SizedBox(height: 12),
            Row(children: [
              CircleAvatar(radius: 16, backgroundColor: AppColors.primaryLight, child: Text(_selectedMail!.sender.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'LXGW WenKai'))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_selectedMail!.sender, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
                Text('${_selectedMail!.createdAt.year}-${_selectedMail!.createdAt.month}-${_selectedMail!.createdAt.day} ${_selectedMail!.createdAt.hour}:${_selectedMail!.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
              ]),
            ]),
            const SizedBox(height: 20),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
            Text(_mailContent ?? _selectedMail!.content, style: const TextStyle(fontSize: 15, height: 1.8, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
          ]),
        ),
      ),
    );
  }
}
