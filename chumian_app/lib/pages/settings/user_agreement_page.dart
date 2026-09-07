import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// UserAgreementPage —— 完整用户协议
/// Miuix 风格可滚动长文页，2000字以上
/// ============================================================
class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

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
          '用户协议',
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
            _buildSection('一、服务说明',
                '欢迎使用初眠AI（以下简称"本服务"）。本用户协议（以下简称"本协议"）是您与初眠AI团队（以下简称"我们"）之间就使用初眠AI服务所订立的协议。请您在使用本服务前仔细阅读本协议的全部内容，特别是以加粗或下划线标注的条款。\n\n初眠AI是一款基于人工智能技术的智能对话与创作应用，为您提供AI聊天、创意写作、联网搜索、图片/视频生成、社区交流、Agent定制等服务。我们致力于为您提供优质、安全、便捷的AI体验。\n\n您通过网络页面点击确认、实际使用本服务或以其他方式表示接受本协议，即视为您已阅读并同意受本协议的约束。如果您不同意本协议的任何内容，请立即停止使用本服务。'),
            _buildSection('二、账号注册与使用',
                '1. 账号注册：您在使用本服务前需要注册一个初眠AI账号。您应提供真实、准确、完整的注册信息（包括用户名、昵称、密码等），并在信息发生变更时及时更新。\n\n2. 账号安全：您应妥善保管账号和密码，对使用该账号进行的所有活动承担责任。如发现账号被盗用或存在安全漏洞，应立即通知我们。因您保管不善导致的账号损失，由您自行承担。\n\n3. 账号归属：初眠AI账号的所有权归我们所有，您仅享有使用权。账号仅限您本人使用，不得赠与、借用、租用、转让或售卖。我们有权根据业务需要回收长期未使用的账号。\n\n4. 实名认证：根据法律法规要求，部分功能可能需要您完成实名认证。您应提供真实的身份信息，我们将依法保护您的个人信息。\n\n5. 未成年人：未满14周岁的未成年人应在监护人陪同下注册和使用本服务。监护人应履行监护职责，对未成年人使用本服务的行为进行监督和指导。'),
            _buildSection('三、用户行为规范',
                '您在使用本服务时应遵守中华人民共和国相关法律法规，不得利用本服务从事任何违法违规或损害他人合法权益的行为，包括但不限于：\n\n1. 不得发布、传播含有以下内容的信息：反对宪法确定的基本原则；危害国家安全、泄露国家秘密、颠覆国家政权、破坏国家统一；损害国家荣誉和利益；煽动民族仇恨、民族歧视，破坏民族团结；破坏国家宗教政策，宣扬邪教和封建迷信；散布谣言，扰乱社会秩序，破坏社会稳定；散布淫秽、色情、赌博、暴力、凶杀、恐怖或者教唆犯罪；侮辱或者诽谤他人，侵害他人合法权益；含有法律、行政法规禁止的其他内容。\n\n2. 不得利用AI生成功能生成违法、有害、侵犯他人权益的内容，包括但不限于深度伪造他人肖像/声音、生成恶意代码、生成虚假信息等。\n\n3. 不得对本服务进行反向工程、反向编译、反汇编，或以其他方式试图获取本服务的源代码。\n\n4. 不得使用任何自动化工具（如爬虫、脚本）大规模访问或干扰本服务的正常运行。\n\n5. 不得攻击、入侵本服务的服务器或网络系统，不得干扰其他用户正常使用本服务。\n\n6. 不得利用本服务从事任何商业活动，包括但不限于售卖AI生成内容、提供付费代聊服务等，除非获得我们的书面授权。\n\n7. 不得冒充他人或虚构身份，不得使用侮辱性、歧视性的用户名或昵称。\n\n如您违反上述行为规范，我们有权视情节轻重采取警告、限制功能、暂停服务、封禁账号等措施，并保留追究法律责任的权利。'),
            _buildSection('四、知识产权',
                '1. 本服务的知识产权：初眠AI应用程序、界面设计、商标、logo、文案、代码、算法模型等全部知识产权均归我们或相关权利人所有，受中华人民共和国知识产权法律法规保护。未经我们书面许可，您不得复制、修改、分发、展示或以其他方式使用。\n\n2. 用户内容的知识产权：您在使用本服务过程中上传、发布的原创内容（如帖子、评论、图片等），其知识产权归您所有。您授予我们一项免费的、非独占的、可再许可的、全球范围内的使用权，用于在本服务中展示、存储、传播您的内容，以及为改进服务质量进行必要的分析和处理。\n\n3. 您保证上传的内容不侵犯任何第三方的知识产权（包括著作权、商标权、专利权等）和其他合法权益。如因您上传的内容引发侵权纠纷，由您自行承担全部法律责任，并赔偿我们因此遭受的损失。\n\n4. 如您认为本服务中的内容侵犯了您的知识产权，请通过本协议末尾的联系方式向我们提交侵权通知，我们将在核实后及时处理。'),
            _buildSection('五、AI生成内容归属与免责',
                '1. 内容归属：您通过初眠AI生成的内容（包括文字、图片、视频、代码等），在符合法律法规和本协议规定的前提下，归您所有。您可以自由使用、复制、修改、分发这些内容，包括商业用途。\n\n2. 免责声明：AI生成内容由人工智能模型自动生成，可能存在不准确、不完整、过时或误导性的信息。我们不对AI生成内容的准确性、完整性、可靠性或适用性作出任何明示或暗示的保证。您在使用AI生成内容时应自行判断和核实，因依赖AI生成内容而造成的任何直接或间接损失，我们不承担责任。\n\n3. 特定领域免责：AI生成内容不构成医疗、法律、金融、投资、税务等专业领域的建议。在涉及健康、法律、财务等重要决策时，请咨询专业人士。\n\n4. 内容审核：我们有权对AI生成内容进行审核，对于违反法律法规或本协议的内容，我们有权删除或拒绝生成。但我们不保证对所有内容进行审核，也不对用户生成的内容承担连带责任。\n\n5. 第三方权利：AI生成内容可能偶然与第三方作品相似，您在使用时应注意不侵犯第三方的知识产权。如因使用AI生成内容引发第三方侵权主张，由您自行承担责任。'),
            _buildSection('六、联网搜索服务条款',
                '1. 服务内容：初眠AI提供联网搜索功能，可在AI对话中实时检索互联网信息，以增强回答的准确性和时效性。\n\n2. 搜索结果：搜索结果由第三方搜索引擎提供，我们不对搜索结果的准确性、完整性、合法性或时效性作出保证。搜索结果中的观点和内容不代表我们的立场。\n\n3. 内容使用：您可以查看和引用搜索结果中的内容，但应遵守原始来源网站的使用条款和知识产权规定。不得利用搜索结果从事任何违法活动。\n\n4. 外部链接：搜索结果可能包含指向第三方网站的链接。我们不对第三方网站的内容、隐私政策或安全性负责。您访问第三方网站时应自行承担风险。\n\n5. 功能开关：您可以随时通过输入框上方的"联网搜索"按钮开启或关闭该功能。关闭后，AI对话将不会进行联网检索。'),
            _buildSection('七、付费服务与积分',
                '1. SVIP会员：初眠AI提供SVIP会员付费服务，会员可享受更多AI对话次数、高级模型使用、优先排队、专属客服等权益。会员费用以购买页面显示的价格为准。\n\n2. 积分系统：初眠AI使用积分作为应用内虚拟货币，可用于兑换高级功能、购买商品等。积分可通过签到、参与活动、完成任务等方式免费获取，也可通过付费购买积分包获得。\n\n3. 付费规则：所有付费服务均为虚拟商品，一经购买不支持退款（法律法规另有规定的除外）。请您在购买前仔细确认商品信息和价格。\n\n4. 积分有效期：通过付费购买的积分长期有效；通过活动、签到等方式免费获取的积分有效期为获取之日起365天，过期自动清零。\n\n5. 价格调整：我们有权根据运营需要调整付费服务和积分包的价格，调整前会通过公告等方式通知您。已购买的服务不受价格调整影响。\n\n6. 禁止行为：不得通过非法手段获取积分或会员权益，不得利用系统漏洞进行套利。一经发现，我们有权扣除违规积分、取消会员资格并封禁账号。'),
            _buildSection('八、免责声明',
                '1. 服务可用性：我们将尽合理努力保持本服务的稳定运行，但不保证本服务不会中断或无错误。因系统维护、网络故障、服务器升级等原因导致的服务中断，我们不承担责任。\n\n2. 不可抗力：因不可抗力（包括但不限于自然灾害、战争、政府行为、网络攻击、电力故障等）导致本服务无法正常使用或数据丢失的，我们不承担责任。\n\n3. 第三方服务：本服务可能集成第三方服务（如支付、搜索、推送等），因第三方服务故障或变更导致的问题，我们不承担责任。\n\n4. 用户数据：我们会定期备份用户数据，但不对因意外情况导致的数据丢失承担责任。建议您自行备份重要的对话记录和内容。\n\n5. 间接损失：在法律允许的最大范围内，我们不对任何间接的、附带的、特殊的或惩罚性的损失承担责任，包括但不限于利润损失、数据丢失、业务中断等。\n\n6. 责任上限：在任何情况下，我们对您承担的全部责任不超过您在过去12个月内向我们支付的费用总额（如有）。'),
            _buildSection('九、服务变更与终止',
                '1. 服务变更：我们有权根据业务发展需要，随时变更、暂停或终止本服务的全部或部分功能。对于重大变更，我们会提前通过公告等方式通知您。\n\n2. 账号终止：您可以随时申请注销账号，终止使用本服务。账号注销后，您的个人信息将被删除或匿名化，已购买的会员和积分将失效且不予退还。\n\n3. 违规终止：如您违反本协议或相关法律法规，我们有权随时暂停或终止向您提供服务，封禁您的账号，且不退还任何已支付的费用。\n\n4. 服务终止：如我们决定终止全部服务，会提前30天通过公告通知您，并为您提供数据导出的窗口期。服务终止后，所有账号和数据将被删除。'),
            _buildSection('十、争议解决',
                '1. 协议适用：本协议的订立、执行、解释及争议解决均适用中华人民共和国法律（不含港澳台地区法律）。\n\n2. 友好协商：如您与我们之间发生争议，应首先通过友好协商解决。\n\n3. 诉讼管辖：协商不成的，任何一方均有权向我们所在地有管辖权的人民法院提起诉讼。\n\n4. 条款独立性：本协议的任何条款被认定为无效或不可执行的，不影响其他条款的效力。\n\n5. 权利保留：我们未行使或延迟行使本协议项下的任何权利，不构成对该权利的放弃。'),
            _buildSection('十一、联系方式',
                '如您对本用户协议有任何疑问、意见或建议，或需要投诉举报，请通过以下方式与我们联系：\n\n- 邮箱：support@chumian-ai.com\n- 客服QQ：800-XXXX-XXXX\n- 应用内反馈：我的-设置-意见反馈\n- 官方网站：www.chumian-ai.com\n\n我们会在收到您的反馈后15个工作日内回复。感谢您选择初眠AI，祝您使用愉快！'),
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
                  Text('生效日期：2026年9月1日', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('版本号：v2.0', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
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
          child: const Icon(Icons.description, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          '初眠AI 用户协议',
          style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xxl, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '请仔细阅读以下协议条款',
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
