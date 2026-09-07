import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// PrivacyPolicyPage —— 完整隐私声明
/// Miuix 风格可滚动长文页，2000字以上
/// ============================================================
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(
        backgroundColor: MiuixColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '隐私政策',
          style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection('一、引言',
                '初眠AI（以下简称"我们"）深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。我们致力于维持您对我们的信任，恪守以下原则保护您的个人信息：权责一致原则、目的明确原则、选择同意原则、最少够用原则、确保安全原则、主体参与原则、公开透明原则等。同时，我们承诺按本隐私政策所述方式收集、使用、存储和共享您的个人信息。'),
            _buildSection('二、信息收集',
                '在您使用初眠AI服务的过程中，我们会收集以下类型的信息：\n\n1. 账号信息：当您注册账号时，我们会收集您的用户名、昵称、密码（加密存储）、邮箱等信息，用于创建和管理您的账号。\n\n2. 聊天内容：您在使用AI对话功能时发送的消息、上传的图片和视频，以及AI生成的回复内容。这些信息用于提供对话服务、改善AI模型质量，并在您主动删除前保存在服务器上。\n\n3. 设备信息：我们会收集设备型号、操作系统版本、设备标识符、屏幕分辨率、网络类型等信息，用于优化应用性能、排查故障和保障账号安全。\n\n4. 日志信息：当您使用我们的服务时，我们会自动收集您的访问时间、访问IP地址、操作记录、崩溃日志等信息，用于安全审计和服务质量监控。\n\n5. 支付信息：当您购买SVIP会员或积分包时，我们会通过第三方支付渠道处理支付，我们不会存储您的银行卡号、密码等敏感支付信息。'),
            _buildSection('三、AI内容免责声明',
                '初眠AI提供的所有AI生成内容（包括但不限于文字回复、图片、视频、代码等）均由人工智能模型自动生成，仅供参考和娱乐用途。AI生成的内容可能存在不准确、不完整或误导性的信息，不构成任何专业建议（包括但不限于医疗、法律、金融、投资等领域的建议）。您在使用AI生成内容时应自行判断其准确性和适用性，我们不对因依赖AI生成内容而造成的任何直接或间接损失承担责任。\n\nAI模型可能会生成与事实不符的内容（即"幻觉"），请您在重要决策前务必核实相关信息。我们会持续优化模型质量，但无法保证AI生成内容的绝对准确性。'),
            _buildSection('四、联网搜索说明',
                '当您开启联网搜索功能时，我们会将您的查询内容发送至第三方搜索引擎进行实时检索，并将搜索结果摘要注入AI对话上下文，以提供更准确、更及时的回答。在此过程中：\n\n1. 您的查询内容会被发送至第三方搜索服务提供商，其使用受对应第三方隐私政策约束。\n2. 搜索结果会以来源卡片的形式展示在AI回复下方，您可以点击查看原始来源。\n3. 您可以随时通过输入框上方的"联网搜索"胶囊按钮关闭该功能，关闭后不会进行联网检索。\n4. AI也可能根据问题类型自主判断是否需要联网搜索，此时会在回复中标注搜索来源。'),
            _buildSection('五、本地存储与Cookie',
                '我们使用本地存储（SharedPreferences）和类似技术来保存您的登录状态、用户偏好设置（如深色模式、通知开关）、主题选择等信息，以提供更流畅的使用体验。这些数据仅存储在您的设备本地，不会上传至服务器（登录令牌除外，用于保持登录状态）。\n\n我们不会使用Cookie追踪您在其他网站上的活动。应用内的本地数据可以通过"设置-清除缓存"功能清除，清除后需要重新登录。'),
            _buildSection('六、权限使用说明',
                '初眠AI在使用过程中可能申请以下系统权限，均在您明确授权后才会使用：\n\n1. 麦克风权限：用于语音输入功能。当您长按麦克风按钮说话时，我们会录制您的语音并进行语音识别，识别完成后音频数据不会长期保存。您可以拒绝该权限，拒绝后仅无法使用语音输入功能，不影响其他功能使用。\n\n2. 存储/相册权限：用于选择和保存图片、视频文件。当您需要在对话中发送图片或保存AI生成的图片/视频时，我们会申请访问相册的权限。您可以拒绝该权限，拒绝后仅无法使用图片/视频相关功能。\n\n3. 网络权限：用于与服务器通信，提供AI对话、联网搜索、社区浏览等核心功能。这是应用正常运行的必要权限。\n\n4. 通知权限：用于向您推送消息通知、活动提醒等。您可以在系统设置中随时关闭通知。\n\n您可以随时在手机系统设置中管理和撤销上述权限。撤销权限后，相关功能将无法使用，但不会影响其他功能的正常运行。'),
            _buildSection('七、数据共享与第三方',
                '我们不会向任何第三方出售您的个人信息。仅在以下情况下，我们可能会共享您的部分信息：\n\n1. 经您明确同意：在获得您的明确授权后，我们会与第三方共享您指定的信息。\n2. 服务提供商：我们可能委托可信的第三方服务提供商（如云服务提供商、支付处理商、搜索引擎）为我们提供必要的技术支持，这些服务商仅能在为我们提供服务的范围内使用您的信息，并受保密协议约束。\n3. 法律要求：在法律法规要求、行政机关或司法机关依法要求的情况下，我们可能会披露您的相关信息。\n4. 保护权利：为保护我们、您或其他用户的合法权益，在必要范围内可能共享相关信息。\n\n我们要求所有第三方服务提供商遵守严格的数据保护标准，并定期审查其合规情况。'),
            _buildSection('八、用户权利',
                '根据相关法律法规，您对您的个人信息享有以下权利：\n\n1. 访问权：您有权访问我们持有的您的个人信息，可在"我的-个人资料"中查看您的账号信息。\n2. 更正权：您有权更正不准确或不完整的个人信息，可在个人资料页面修改昵称、头像等信息。\n3. 删除权：在特定情形下（如您撤回同意、我们违反法律规定等），您有权要求删除您的个人信息。您可以通过删除对话记录清除聊天内容，或通过注销账号清除全部个人信息。\n4. 注销账号：您有权随时注销您的初眠AI账号。注销后，我们将删除或匿名化您的全部个人信息，但法律法规要求保留的除外。注销操作不可恢复，请谨慎操作。\n5. 撤回同意：您有权撤回之前给予的任何同意，撤回同意不影响撤回前基于同意已进行的信息处理。\n6. 投诉权：您有权向相关监管部门投诉我们的个人信息处理行为。\n\n如需行使上述权利，请通过本政策末尾的联系方式与我们联系，我们将在15个工作日内回复您的请求。'),
            _buildSection('九、未成年人保护',
                '我们非常重视未成年人的个人信息保护。初眠AI的主要用户群体为成年人。如果您是未满14周岁的未成年人，请在监护人的陪同和指导下阅读本政策并使用我们的服务。如果您是未满14周岁未成年人的监护人，在您的孩子使用我们的服务前，请您仔细阅读本政策并决定是否同意。\n\n对于经监护人同意收集的未成年人个人信息，我们只会在法律允许、监护人明确同意或保护未成年人所必要的范围内使用、共享或披露。如果我们发现在未事先获得可证实的监护人同意的情况下收集了未成年人的个人信息，会尽快删除相关数据。\n\n未成年人不得自行购买SVIP会员或积分包，相关付费操作需在监护人指导下进行。'),
            _buildSection('十、数据安全',
                '我们采取多种技术和管理措施保护您的个人信息安全：\n\n1. 传输加密：所有数据传输均采用HTTPS/TLS加密协议，防止数据在传输过程中被窃取或篡改。\n2. 存储加密：用户密码采用加盐哈希算法加密存储，敏感信息采用AES-256加密存储。\n3. 访问控制：严格限制员工对用户数据的访问权限，仅在必要范围内授权，并记录所有数据访问操作。\n4. 安全审计：定期进行安全审计和渗透测试，及时发现和修复安全漏洞。\n5. 数据备份：定期备份用户数据，确保在发生故障时能够快速恢复。\n\n尽管我们采取了上述安全措施，但互联网环境并非百分之百安全，我们将尽力确保您的信息安全。如果发生个人信息安全事件，我们将按照法律法规要求及时通知您事件的基本情况、可能的影响、我们已采取或将要采取的处置措施等。'),
            _buildSection('十一、政策更新',
                '我们可能会根据业务发展或法律法规的变化适时修订本隐私政策。当政策发生重大变更时，我们会通过应用内弹窗、推送通知或公告等显著方式通知您。对于重大变更，我们还会再次征求您的同意。\n\n您可以在本页面顶部查看本政策的更新日期。建议您定期查阅本政策以了解最新内容。您继续使用我们的服务即表示同意受修订后的隐私政策约束。'),
            _buildSection('十二、联系方式',
                '如果您对本隐私政策有任何疑问、意见或建议，或需要行使您的个人信息权利，请通过以下方式与我们联系：\n\n- 邮箱：privacy@chumian-ai.com\n- 客服QQ：800-XXXX-XXXX\n- 应用内反馈：我的-设置-意见反馈\n\n我们会在收到您的请求后15个工作日内回复。如果您对我们的回复不满意，特别是认为我们的个人信息处理行为损害了您的合法权益，您还可以向网信、公安、工商等监管部门进行投诉或举报。'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MiuixColors.primary.withValues(alpha: 0.06),
                borderRadius: MiuixRadius.mdRadius,
                border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('更新日期：2026年9月1日', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('生效日期：2026年9月1日', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
                  const SizedBox(height: 8),
                  Text('初眠AI团队 版权所有', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            boxShadow: MiuixShadows.md,
          ),
          child: const Icon(Icons.privacy_tip, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          '初眠AI 隐私政策',
          style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xxl, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '我们承诺保护您的个人信息安全',
          style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [MiuixColors.primary.withValues(alpha: 0.12), MiuixColors.primary.withValues(alpha: 0.04)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(MiuixRadius.md),
                topRight: const Radius.circular(MiuixRadius.md),
                bottomRight: const Radius.circular(MiuixRadius.md),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, height: 1.8),
          ),
        ],
      ),
    );
  }
}
