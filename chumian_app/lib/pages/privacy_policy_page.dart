import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('隐私声明', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
          child: const Text('''初眠AI 隐私声明

更新日期：2026年9月5日

初眠AI（以下简称"我们"）非常重视用户的隐私保护。本隐私声明说明我们如何收集、使用、存储和保护您的个人信息。

一、信息收集
1. 注册信息：您注册时提供的邮箱、昵称、密码。
2. 使用信息：您的对话记录、生成的图片/视频、使用的模型。
3. 设备信息：设备型号、操作系统版本、应用版本。
4. GitHub账号信息（如您选择绑定）：GitHub ID、用户名、头像。

二、信息使用
1. 提供AI对话、创作、搜索等核心服务。
2. 改进和优化产品体验。
3. 账号安全验证和异常检测。
4. 积分系统和活动运营。

三、信息存储
1. 您的数据存储在我们的安全服务器上。
2. 对话记录用于提供历史对话功能，您可随时删除。
3. 我们不会将您的个人信息出售给第三方。

四、信息安全
1. 采用加密传输（HTTPS）保护数据。
2. 密码使用哈希加密存储。
3. 定期进行安全审计和漏洞修复。

五、您的权利
1. 访问、更正您的个人信息。
2. 删除您的账号和相关数据。
3. 撤回授权同意。
4. 注销账号。

六、未成年人保护
我们非常重视未成年人的隐私保护。若您是未满14周岁的未成年人，请在监护人陪同下使用本服务。

七、联系我们
如有任何隐私相关问题，请联系：3835347820@qq.com

八、声明更新
我们可能会适时更新本隐私声明，更新后将在应用内公示。继续使用即表示您同意更新后的声明。
''', style: TextStyle(fontSize: 14, height: 1.8, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
        ),
      ),
    );
  }
}
