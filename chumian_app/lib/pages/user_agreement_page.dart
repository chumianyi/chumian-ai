import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('用户协议', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.pink500), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('初眠AI用户服务协议', style: AppTextStyles.headingLarge.copyWith(color: AppColors.pink600)),
            const SizedBox(height: 8),
            Text('生效日期：2026年9月1日', style: AppTextStyles.caption.copyWith(color: AppColors.pink400)),
            const SizedBox(height: 20),
            _buildSection('一、协议的接受与修改',
                '欢迎使用初眠AI（以下简称"本应用"）。本协议是您与初眠AI运营方之间就使用本应用服务所订立的协议。请您在使用本应用前仔细阅读本协议的全部内容。\n\n您点击"同意"或实际使用本应用服务，即表示您已充分阅读、理解并接受本协议的全部内容。如果您不同意本协议的任何内容，请停止使用本应用。\n\n我们有权根据需要不时修改本协议，修改后的协议会在本应用内公布。继续使用本应用即表示您接受修改后的协议。'),
            _buildSection('二、服务内容',
                '本应用为您提供以下AI服务：\n\n1. 多模型AI对话：支持GLM、Kimi等多种大语言模型的智能对话，包括流式输出、思考过程展示、Markdown渲染等功能；\n\n2. AI创作：包括图片生成、视频生成、文章写作、代码生成、音乐创作等功能；\n\n3. 联网搜索：AI辅助的网络信息检索与整合；\n\n4. 智能体：预设和自定义的AI智能体服务；\n\n5. 社区探索：用户创作内容的分享与发现；\n\n6. 积分系统：签到、活动、任务等积分获取与使用；\n\n7. 其他我们不时推出的功能和服务。\n\n我们保留随时变更、中断或终止部分或全部服务的权利。'),
            _buildSection('三、账号注册与使用',
                '1. 您在使用本应用部分功能时需要注册账号。您应提供真实、准确、完整的注册信息，并及时更新。\n\n2. 您应妥善保管账号和密码，对账号下的所有活动承担责任。如发现账号被盗用或存在安全漏洞，应立即通知我们。\n\n3. 您不得将账号转让、出借给他人使用。因账号转让或出借导致的损失由您自行承担。\n\n4. 我们有权根据业务需要对账号进行回收、注销或限制使用。'),
            _buildSection('四、用户行为规范',
                '您在使用本应用时应遵守以下规范：\n\n1. 遵守中华人民共和国法律法规，不得利用本应用从事违法违规活动；\n\n2. 不得发布、传播含有以下内容的信息：反对宪法确定的基本原则、危害国家安全、泄露国家秘密、颠覆国家政权、破坏国家统一、煽动民族仇恨、宣扬邪教和封建迷信、散布谣言、扰乱社会秩序、散布淫秽色情暴力凶杀恐怖或者教唆犯罪、侮辱诽谤他人、侵害他人合法权益等；\n\n3. 不得利用AI生成功能生成违法、侵权、有害或不当内容；\n\n4. 不得对本应用进行反向工程、反向编译、反向汇编或其他试图获取源代码的行为；\n\n5. 不得使用自动化工具、脚本或机器人批量访问本应用；\n\n6. 不得干扰或破坏本应用的正常运行，不得攻击本应用的服务器或网络；\n\n7. 不得侵犯他人的知识产权、隐私权、名誉权等合法权益；\n\n8. 不得利用本应用从事任何可能对互联网正常运转造成不利影响的行为。\n\n违反上述规范的，我们有权采取警告、限制功能、封禁账号等措施，并保留追究法律责任的权利。'),
            _buildSection('五、知识产权',
                '1. 本应用的软件代码、界面设计、商标、标识等知识产权均归我们所有，受法律保护。\n\n2. 您通过本应用创作的内容（包括但不限于图片、视频、文章、代码等），其知识产权归您所有，但您授予我们免费的、非独占的、可再许可的使用权，用于提供和改进服务。\n\n3. AI生成内容的知识产权归属可能因内容类型和适用法律而异。您应自行评估并承担使用AI生成内容的风险。\n\n4. 您不得删除或修改本应用中的版权声明或其他权利声明。'),
            _buildSection('六、服务费用与积分',
                '1. 本应用部分功能可能需要付费使用，具体收费标准以应用内公布为准。\n\n2. 积分是本应用内的虚拟货币，可通过签到、活动、任务等方式获取，可用于兑换部分服务。积分不可兑换现金，不可转让。\n\n3. 我们有权调整积分的获取规则和使用范围。\n\n4. 付费服务一经购买，除法律另有规定外，一般不予退款。'),
            _buildSection('七、免责声明',
                '1. AI生成的内容仅供参考，不构成任何专业建议（包括但不限于法律、医疗、金融、投资等）。您应自行判断和评估AI生成内容的准确性和适用性。\n\n2. 我们不保证AI生成内容的准确性、完整性、可靠性或适用性。因使用AI生成内容导致的任何损失，我们不承担责任。\n\n3. 本应用可能因系统维护、网络故障、第三方服务中断等原因无法正常使用，我们不承担由此造成的损失。\n\n4. 因不可抗力导致服务中断或数据丢失的，我们不承担责任。\n\n5. 您通过本应用与第三方进行的交易或互动，由您与第三方自行承担责任。'),
            _buildSection('八、服务的变更与终止',
                '1. 我们有权随时变更、暂停或终止本应用的部分或全部服务，无需事先通知。\n\n2. 如您违反本协议，我们有权暂停或终止向您提供服务。\n\n3. 服务终止后，您的账号和相关数据可能被删除或匿名化处理。'),
            _buildSection('九、法律适用与争议解决',
                '1. 本协议的订立、执行和解释均适用中华人民共和国法律。\n\n2. 因本协议引起的或与本协议有关的任何争议，双方应友好协商解决；协商不成的，任何一方均可向我们所在地有管辖权的人民法院提起诉讼。'),
            _buildSection('十、其他条款',
                '1. 本协议中的标题仅为方便阅读而设，不影响条款的解释。\n\n2. 本协议任何条款被认定为无效或不可执行，不影响其他条款的效力。\n\n3. 我们未行使或延迟行使本协议项下的任何权利，不构成对该权利的放弃。\n\n4. 本协议构成双方关于本主题的完整协议，取代之前的所有口头或书面协议。\n\n5. 如您对本协议有任何疑问，请通过邮箱 contact@chumianai.com 联系我们。'),
            const SizedBox(height: 30),
            Center(
              child: Text('感谢您使用初眠AI', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pink400)),
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
