import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('隐私声明', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.pink500), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('初眠AI隐私政策', style: AppTextStyles.headingLarge.copyWith(color: AppColors.pink600)),
            const SizedBox(height: 8),
            Text('更新日期：2026年9月1日', style: AppTextStyles.caption.copyWith(color: AppColors.pink400)),
            const SizedBox(height: 20),
            _buildSection('一、引言',
                '欢迎使用初眠AI（以下简称"本应用"）。我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。我们致力于维持您对我们的信任，恪守以下原则保护您的个人信息：权责一致原则、目的明确原则、选择同意原则、最少够用原则、确保安全原则、主体参与原则、公开透明原则等。'),
            _buildSection('二、我们收集的信息',
                '在您使用本应用的过程中，我们可能会收集以下类型的信息：\n\n1. 账号信息：当您注册账号时，我们会收集您的用户名、邮箱地址、手机号码等信息。\n\n2. 使用信息：我们会收集您使用本应用的日志信息，包括访问时间、访问页面、操作记录等。\n\n3. 对话内容：为了提供AI对话服务，我们会处理您发送的消息内容。这些内容仅用于生成回复，不会用于其他目的。\n\n4. 设备信息：我们可能会收集您的设备型号、操作系统版本、唯一设备标识符等信息。\n\n5. 创作内容：当您使用图片生成、视频生成等功能时，我们会处理您输入的提示词和生成的内容。'),
            _buildSection('三、信息的使用',
                '我们收集您的个人信息主要用于以下目的：\n\n1. 提供、维护和改进本应用的服务；\n2. 向您发送服务通知和更新信息；\n3. 分析使用趋势以改善用户体验；\n4. 防止欺诈和滥用行为；\n5. 遵守法律法规的要求。\n\n我们不会将您的个人信息出售给任何第三方。'),
            _buildSection('四、信息的共享与披露',
                '我们仅在以下情况下可能共享您的个人信息：\n\n1. 获得您的明确同意；\n2. 与我们的服务提供商共享，用于提供必要的技术支持（如云存储、AI模型服务）；\n3. 法律法规要求或政府主管部门强制性要求；\n4. 为维护我们及用户的合法权益。\n\n我们要求所有第三方服务提供商遵守严格的数据保护标准。'),
            _buildSection('五、信息的存储与安全',
                '我们采用行业标准的安全措施保护您的个人信息，包括：\n\n1. 数据传输采用SSL/TLS加密；\n2. 敏感数据存储采用加密处理；\n3. 访问权限严格控制，仅授权人员可访问；\n4. 定期进行安全审计和漏洞扫描。\n\n您的个人信息存储在中华人民共和国境内的服务器上。我们会在实现目的所必需的最短时间内保留您的个人信息。'),
            _buildSection('六、您的权利',
                '您对您的个人信息享有以下权利：\n\n1. 访问权：您可以随时查看您的个人信息；\n2. 更正权：您可以要求更正不准确的信息；\n3. 删除权：您可以要求删除您的个人信息；\n4. 撤回同意权：您可以撤回之前给予的同意；\n5. 注销账号权：您可以注销您的账号。\n\n如需行使上述权利，请通过应用内的反馈渠道联系我们。'),
            _buildSection('七、未成年人保护',
                '本应用主要面向成年人。如果您是未满14周岁的未成年人，请在监护人的陪同下阅读本政策，并在监护人同意的情况下使用本应用。我们不会主动收集未成年人的个人信息。'),
            _buildSection('八、Cookie和类似技术',
                '本应用可能使用Cookie和类似技术来改善用户体验，包括记住您的偏好设置、保持登录状态等。您可以在设备设置中管理或禁用Cookie，但这可能影响部分功能的使用。'),
            _buildSection('九、政策更新',
                '我们可能会不时更新本隐私政策。更新后的政策会在本应用内公布，重大变更会通过通知方式告知您。继续使用本应用即表示您同意更新后的政策。'),
            _buildSection('十、联系我们',
                '如果您对本隐私政策有任何疑问、意见或建议，或需要行使您的个人信息权利，请通过以下方式联系我们：\n\n邮箱：privacy@chumianai.com\n\n我们会在收到您的请求后15个工作日内回复。'),
            const SizedBox(height: 30),
            Center(
              child: Text('感谢您信任初眠AI', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pink400)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall.copyWith(color: AppColors.pink600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.3), blurRadius: 4)],
            ),
            child: Text(content, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.7)),
          ),
        ],
      ),
    );
  }
}
