import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('用户协议', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
          child: const Text('''初眠AI 用户服务协议

更新日期：2026年9月5日

欢迎使用初眠AI！在使用本服务前，请仔细阅读本协议。

第一条 服务内容
1. 初眠AI提供AI对话、图片生成、视频生成、联网搜索、智能体、社区等服务。
2. 我们接入GLM、Kimi等第三方大模型，服务质量受第三方影响。
3. 部分功能需要消耗积分，积分规则以应用内公示为准。

第二条 账号注册与使用
1. 您需使用有效邮箱注册账号，确保信息真实准确。
2. 您应妥善保管账号密码，因账号泄露造成的损失由您自行承担。
3. 禁止将账号转借、出租、出售给他人使用。
4. 每个用户每日有免费积分额度，超出后需等待次日重置或购买。

第三条 用户行为规范
1. 不得利用本服务发布违法、违规、侵权内容。
2. 不得尝试破解、逆向工程、攻击本服务。
3. 不得批量注册账号、刷积分、滥用API。
4. 不得生成涉及色情、暴力、恐怖、赌博、毒品、自杀、杀人、炸弹、枪支、反动等违禁内容。
5. 违反上述规定的，我们有权封禁账号。

第四条 知识产权
1. 本应用的代码、设计、商标等知识产权归初眠AI所有。
2. 用户通过本服务生成的内容，用户享有使用权，但不得用于违法用途。
3. AI生成内容可能存在不准确，请勿作为重要决策依据。

第五条 免责声明
1. AI生成内容仅供参考，不构成专业建议。
2. 因网络、第三方服务故障导致的服务中断，我们不承担责任。
3. 因不可抗力导致的服务暂停或终止，我们不承担责任。
4. 本地模型推理速度较慢，属于正常现象。

第六条 服务变更与终止
1. 我们有权根据运营需要调整、暂停或终止部分服务。
2. 如您违反本协议，我们有权终止提供服务。
3. 账号注销后，相关数据将被删除或匿名化处理。

第七条 协议修改
我们可能会适时修改本协议，修改后将在应用内公示。继续使用即表示您同意修改后的协议。

第八条 联系方式
如有疑问，请联系：3835347820@qq.com

第九条 法律适用
本协议适用中华人民共和国法律。如发生争议，双方应友好协商解决；协商不成的，提交服务提供者所在地人民法院诉讼解决。
''', style: TextStyle(fontSize: 14, height: 1.8, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
        ),
      ),
    );
  }
}
