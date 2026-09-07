/// ============================================================================
/// PinyinUtils —— 汉字转拼音工具类
///
/// 提供汉字转拼音（简易映射表）、首字母提取、排序辅助、
/// 搜索匹配、常见多音字处理等功能。
///
/// 注意：此为简易实现，使用内置常用汉字映射表，不覆盖全部汉字。
/// 对于生僻字会返回原字符。
/// ============================================================================
class PinyinUtils {
  // ==========================================================================
  // 常用汉字拼音映射表（按 Unicode 范围的常用字）
  // 由于完整映射表过大，这里提供常用字的映射，
  // 未覆盖的汉字通过字符范围估算或返回原字符。
  // ==========================================================================

  /// 常用汉字拼音映射（精选高频字）
  static const Map<String, String> _pinyinMap = {
    '阿': 'a', '啊': 'a', '哎': 'ai', '哀': 'ai', '挨': 'ai', '矮': 'ai',
    '爱': 'ai', '碍': 'ai', '安': 'an', '按': 'an', '暗': 'an', '岸': 'an',
    '昂': 'ang', '凹': 'ao', '傲': 'ao', '奥': 'ao',
    '八': 'ba', '巴': 'ba', '拔': 'ba', '把': 'ba', '爸': 'ba', '罢': 'ba',
    '白': 'bai', '百': 'bai', '摆': 'bai', '败': 'bai', '拜': 'bai',
    '班': 'ban', '般': 'ban', '板': 'ban', '版': 'ban', '办': 'ban',
    '半': 'ban', '伴': 'ban', '帮': 'bang', '包': 'bao', '宝': 'bao',
    '保': 'bao', '报': 'bao', '抱': 'bao', '暴': 'bao', '杯': 'bei',
    '悲': 'bei', '北': 'bei', '背': 'bei', '被': 'bei', '倍': 'bei',
    '备': 'bei', '本': 'ben', '笨': 'ben', '崩': 'beng', '逼': 'bi',
    '鼻': 'bi', '比': 'bi', '笔': 'bi', '彼': 'bi', '碧': 'bi',
    '蔽': 'bi', '壁': 'bi', '避': 'bi', '边': 'bian', '编': 'bian',
    '贬': 'bian', '便': 'bian', '变': 'bian', '遍': 'bian', '标': 'biao',
    '表': 'biao', '别': 'bie', '宾': 'bin', '冰': 'bing', '兵': 'bing',
    '饼': 'bing', '并': 'bing', '病': 'bing', '拨': 'bo', '波': 'bo',
    '博': 'bo', '薄': 'bo', '补': 'bu', '捕': 'bu', '不': 'bu',
    '布': 'bu', '步': 'bu', '部': 'bu',
    '擦': 'ca', '猜': 'cai', '才': 'cai', '材': 'cai', '财': 'cai',
    '采': 'cai', '彩': 'cai', '菜': 'cai', '参': 'can', '餐': 'can',
    '残': 'can', '惨': 'can', '灿': 'can', '仓': 'cang', '苍': 'cang',
    '藏': 'cang', '操': 'cao', '草': 'cao', '册': 'ce', '侧': 'ce',
    '测': 'ce', '层': 'ceng', '叉': 'cha', '插': 'cha', '查': 'cha',
    '茶': 'cha', '察': 'cha', '差': 'cha', '拆': 'chai', '柴': 'chai',
    '缠': 'chan', '产': 'chan', '颤': 'chan', '长': 'chang', '肠': 'chang',
    '尝': 'chang', '常': 'chang', '场': 'chang', '唱': 'chang', '倡': 'chang',
    '抄': 'chao', '超': 'chao', '朝': 'chao', '潮': 'chao', '吵': 'chao',
    '炒': 'chao', '车': 'che', '扯': 'che', '彻': 'che', '沉': 'chen',
    '陈': 'chen', '晨': 'chen', '称': 'chen', '趁': 'chen', '成': 'cheng',
    '承': 'cheng', '城': 'cheng', '乘': 'cheng', '程': 'cheng', '惩': 'cheng',
    '吃': 'chi', '池': 'chi', '迟': 'chi', '持': 'chi', '尺': 'chi',
    '齿': 'chi', '耻': 'chi', '斥': 'chi', '赤': 'chi', '翅': 'chi',
    '充': 'chong', '冲': 'chong', '虫': 'chong', '崇': 'chong', '抽': 'chou',
    '仇': 'chou', '愁': 'chou', '丑': 'chou', '臭': 'chou', '出': 'chu',
    '初': 'chu', '除': 'chu', '楚': 'chu', '触': 'chu', '处': 'chu',
    '川': 'chuan', '穿': 'chuan', '传': 'chuan', '船': 'chuan', '喘': 'chuan',
    '串': 'chuan', '窗': 'chuang', '床': 'chuang', '创': 'chuang', '吹': 'chui',
    '垂': 'chui', '锤': 'chui', '春': 'chun', '纯': 'chun', '唇': 'chun',
    '词': 'ci', '慈': 'ci', '辞': 'ci', '此': 'ci', '次': 'ci',
    '刺': 'ci', '从': 'cong', '丛': 'cong', '凑': 'cou', '粗': 'cu',
    '促': 'cu', '催': 'cui', '脆': 'cui', '翠': 'cui', '村': 'cun',
    '存': 'cun', '寸': 'cun', '错': 'cuo', '措': 'cuo',
    '搭': 'da', '达': 'da', '答': 'da', '打': 'da', '大': 'da',
    '呆': 'dai', '代': 'dai', '带': 'dai', '待': 'dai', '袋': 'dai',
    '逮': 'dai', '单': 'dan', '担': 'dan', '胆': 'dan', '但': 'dan',
    '淡': 'dan', '弹': 'dan', '蛋': 'dan', '当': 'dang', '挡': 'dang',
    '党': 'dang', '荡': 'dang', '刀': 'dao', '导': 'dao', '岛': 'dao',
    '倒': 'dao', '到': 'dao', '道': 'dao', '得': 'de', '德': 'de',
    '的': 'de', '灯': 'deng', '登': 'deng', '等': 'deng', '凳': 'deng',
    '低': 'di', '底': 'di', '抵': 'di', '地': 'di', '弟': 'di',
    '帝': 'di', '递': 'di', '第': 'di', '颠': 'dian', '点': 'dian',
    '典': 'dian', '电': 'dian', '店': 'dian', '垫': 'dian', '雕': 'diao',
    '掉': 'diao', '吊': 'diao', '调': 'diao', '跌': 'die', '叠': 'die',
    '丁': 'ding', '顶': 'ding', '订': 'ding', '定': 'ding', '丢': 'diu',
    '东': 'dong', '冬': 'dong', '懂': 'dong', '动': 'dong', '冻': 'dong',
    '洞': 'dong', '都': 'dou', '斗': 'dou', '抖': 'dou', '豆': 'dou',
    '逗': 'dou', '毒': 'du', '读': 'du', '独': 'du', '堵': 'du',
    '赌': 'du', '杜': 'du', '肚': 'du', '度': 'du', '渡': 'du',
    '端': 'duan', '短': 'duan', '段': 'duan', '断': 'duan', '锻': 'duan',
    '堆': 'dui', '队': 'dui', '对': 'dui', '吨': 'dun', '蹲': 'dun',
    '盾': 'dun', '顿': 'dun', '多': 'duo', '夺': 'duo', '朵': 'duo',
    '躲': 'duo', '堕': 'duo',
    '鹅': 'e', '额': 'e', '恶': 'e', '饿': 'e', '恩': 'en',
    '儿': 'er', '而': 'er', '耳': 'er', '二': 'er',
    '发': 'fa', '乏': 'fa', '罚': 'fa', '法': 'fa', '帆': 'fan',
    '番': 'fan', '翻': 'fan', '凡': 'fan', '烦': 'fan', '繁': 'fan',
    '反': 'fan', '返': 'fan', '犯': 'fan', '泛': 'fan', '饭': 'fan',
    '范': 'fan', '贩': 'fan', '方': 'fang', '坊': 'fang', '芳': 'fang',
    '防': 'fang', '妨': 'fang', '仿': 'fang', '访': 'fang', '纺': 'fang',
    '放': 'fang', '飞': 'fei', '非': 'fei', '肥': 'fei', '废': 'fei',
    '沸': 'fei', '费': 'fei', '分': 'fen', '纷': 'fen', '坟': 'fen',
    '粉': 'fen', '份': 'fen', '奋': 'fen', '愤': 'fen', '丰': 'feng',
    '风': 'feng', '封': 'feng', '疯': 'feng', '峰': 'feng', '锋': 'feng',
    '蜂': 'feng', '逢': 'feng', '缝': 'feng', '凤': 'feng', '奉': 'feng',
    '佛': 'fo', '否': 'fou', '夫': 'fu', '肤': 'fu', '孵': 'fu',
    '扶': 'fu', '服': 'fu', '浮': 'fu', '符': 'fu', '幅': 'fu',
    '福': 'fu', '斧': 'fu', '俯': 'fu', '府': 'fu', '腐': 'fu',
    '父': 'fu', '付': 'fu', '妇': 'fu', '负': 'fu', '附': 'fu',
    '复': 'fu', '副': 'fu', '富': 'fu', '赋': 'fu', '腹': 'fu',
    '覆': 'fu',
    '该': 'gai', '改': 'gai', '盖': 'gai', '概': 'gai', '干': 'gan',
    '甘': 'gan', '杆': 'gan', '肝': 'gan', '赶': 'gan', '敢': 'gan',
    '感': 'gan', '刚': 'gang', '岗': 'gang', '港': 'gang', '杠': 'gang',
    '高': 'gao', '搞': 'gao', '稿': 'gao', '告': 'gao', '哥': 'ge',
    '歌': 'ge', '阁': 'ge', '革': 'ge', '格': 'ge', '隔': 'ge',
    '个': 'ge', '各': 'ge', '给': 'gei', '根': 'gen', '跟': 'gen',
    '更': 'geng', '耕': 'geng', '工': 'gong', '弓': 'gong', '公': 'gong',
    '功': 'gong', '攻': 'gong', '供': 'gong', '宫': 'gong', '恭': 'gong',
    '共': 'gong', '勾': 'gou', '沟': 'gou', '狗': 'gou', '构': 'gou',
    '购': 'gou', '够': 'gou', '估': 'gu', '姑': 'gu', '孤': 'gu',
    '古': 'gu', '谷': 'gu', '股': 'gu', '骨': 'gu', '鼓': 'gu',
    '固': 'gu', '故': 'gu', '顾': 'gu', '瓜': 'gua', '刮': 'gua',
    '挂': 'gua', '乖': 'guai', '拐': 'guai', '怪': 'guai', '关': 'guan',
    '观': 'guan', '官': 'guan', '管': 'guan', '馆': 'guan', '贯': 'guan',
    '惯': 'guan', '灌': 'guan', '光': 'guang', '广': 'guang', '归': 'gui',
    '龟': 'gui', '规': 'gui', '轨': 'gui', '鬼': 'gui', '柜': 'gui',
    '贵': 'gui', '桂': 'gui', '滚': 'gun', '棍': 'gun', '锅': 'guo',
    '国': 'guo', '果': 'guo', '裹': 'guo', '过': 'guo',
    '哈': 'ha', '孩': 'hai', '海': 'hai', '害': 'hai', '含': 'han',
    '寒': 'han', '韩': 'han', '汉': 'han', '汗': 'han', '旱': 'han',
    '杭': 'hang', '航': 'hang', '豪': 'hao', '毫': 'hao', '好': 'hao',
    '号': 'hao', '浩': 'hao', '喝': 'he', '合': 'he', '何': 'he',
    '和': 'he', '河': 'he', '核': 'he', '荷': 'he', '贺': 'he',
    '黑': 'hei', '痕': 'hen', '很': 'hen', '狠': 'hen', '恨': 'hen',
    '哼': 'heng', '恒': 'heng', '横': 'heng', '轰': 'hong', '红': 'hong',
    '宏': 'hong', '洪': 'hong', '虹': 'hong', '喉': 'hou', '猴': 'hou',
    '吼': 'hou', '后': 'hou', '厚': 'hou', '候': 'hou', '呼': 'hu',
    '忽': 'hu', '狐': 'hu', '胡': 'hu', '壶': 'hu', '湖': 'hu',
    '蝴': 'hu', '虎': 'hu', '互': 'hu', '户': 'hu', '护': 'hu',
    '花': 'hua', '华': 'hua', '哗': 'hua', '滑': 'hua', '画': 'hua',
    '话': 'hua', '怀': 'huai', '坏': 'huai', '欢': 'huan', '环': 'huan',
    '还': 'huan', '缓': 'huan', '换': 'huan', '唤': 'huan', '患': 'huan',
    '荒': 'huang', '黄': 'huang', '煌': 'huang', '晃': 'huang', '灰': 'hui',
    '挥': 'hui', '恢': 'hui', '回': 'hui', '毁': 'hui', '悔': 'hui',
    '会': 'hui', '绘': 'hui', '贿': 'hui', '昏': 'hun', '婚': 'hun',
    '魂': 'hun', '混': 'hun', '活': 'huo', '火': 'huo', '伙': 'huo',
    '或': 'huo', '货': 'huo', '获': 'huo', '祸': 'huo', '惑': 'huo',
    '击': 'ji', '饥': 'ji', '机': 'ji', '肌': 'ji', '鸡': 'ji',
    '迹': 'ji', '积': 'ji', '基': 'ji', '绩': 'ji', '激': 'ji',
    '及': 'ji', '吉': 'ji', '级': 'ji', '即': 'ji', '极': 'ji',
    '急': 'ji', '疾': 'ji', '集': 'ji', '籍': 'ji', '几': 'ji',
    '己': 'ji', '挤': 'ji', '脊': 'ji', '计': 'ji', '记': 'ji',
    '技': 'ji', '际': 'ji', '季': 'ji', '既': 'ji', '继': 'ji',
    '寄': 'ji', '加': 'jia', '佳': 'jia', '家': 'jia', '嘉': 'jia',
    '甲': 'jia', '假': 'jia', '价': 'jia', '架': 'jia', '驾': 'jia',
    '尖': 'jian', '坚': 'jian', '间': 'jian', '肩': 'jian', '艰': 'jian',
    '兼': 'jian', '监': 'jian', '减': 'jian', '剪': 'jian', '检': 'jian',
    '简': 'jian', '见': 'jian', '建': 'jian', '剑': 'jian', '健': 'jian',
    '渐': 'jian', '践': 'jian', '鉴': 'jian', '键': 'jian', '江': 'jiang',
    '将': 'jiang', '姜': 'jiang', '讲': 'jiang', '奖': 'jiang', '匠': 'jiang',
    '降': 'jiang', '蕉': 'jiao', '交': 'jiao', '郊': 'jiao', '浇': 'jiao',
    '骄': 'jiao', '胶': 'jiao', '角': 'jiao', '脚': 'jiao', '搅': 'jiao',
    '叫': 'jiao', '教': 'jiao', '阶': 'jie', '接': 'jie', '结': 'jie',
    '街': 'jie', '截': 'jie', '节': 'jie', '杰': 'jie', '洁': 'jie',
    '解': 'jie', '介': 'jie', '界': 'jie', '借': 'jie', '届': 'jie',
    '巾': 'jin', '今': 'jin', '金': 'jin', '津': 'jin', '筋': 'jin',
    '紧': 'jin', '锦': 'jin', '尽': 'jin', '进': 'jin', '近': 'jin',
    '晋': 'jin', '浸': 'jin', '禁': 'jin', '京': 'jing', '经': 'jing',
    '茎': 'jing', '惊': 'jing', '晶': 'jing', '睛': 'jing', '精': 'jing',
    '井': 'jing', '颈': 'jing', '景': 'jing', '警': 'jing', '净': 'jing',
    '径': 'jing', '竞': 'jing', '竟': 'jing', '敬': 'jing', '境': 'jing',
    '镜': 'jing', '纠': 'jiu', '究': 'jiu', '九': 'jiu', '久': 'jiu',
    '酒': 'jiu', '旧': 'jiu', '救': 'jiu', '就': 'jiu', '舅': 'jiu',
    '拘': 'ju', '居': 'ju', '菊': 'ju', '局': 'ju', '咀': 'ju',
    '举': 'ju', '矩': 'ju', '句': 'ju', '巨': 'ju', '具': 'ju',
    '俱': 'ju', '剧': 'ju', '惧': 'ju', '据': 'ju', '距': 'ju',
    '聚': 'ju', '捐': 'juan', '卷': 'juan', '倦': 'juan', '决': 'jue',
    '绝': 'jue', '觉': 'jue', '掘': 'jue', '嚼': 'jue', '军': 'jun',
    '君': 'jun', '均': 'jun', '菌': 'jun', '俊': 'jun', '峻': 'jun',
    '骏': 'jun',
    '咖': 'ka', '卡': 'ka', '开': 'kai', '凯': 'kai', '慨': 'kai',
    '刊': 'kan', '看': 'kan', '康': 'kang', '扛': 'kang', '抗': 'kang',
    '考': 'kao', '烤': 'kao', '靠': 'kao', '科': 'ke', '棵': 'ke',
    '颗': 'ke', '壳': 'ke', '咳': 'ke', '可': 'ke', '渴': 'ke',
    '克': 'ke', '刻': 'ke', '客': 'ke', '课': 'ke', '肯': 'ken',
    '坑': 'keng', '空': 'kong', '孔': 'kong', '恐': 'kong', '控': 'kong',
    '口': 'kou', '扣': 'kou', '寇': 'kou', '枯': 'ku', '哭': 'ku',
    '苦': 'ku', '酷': 'ku', '裤': 'ku', '夸': 'kua', '跨': 'kua',
    '块': 'kuai', '快': 'kuai', '宽': 'kuan', '款': 'kuan', '筐': 'kuang',
    '狂': 'kuang', '况': 'kuang', '矿': 'kuang', '旷': 'kuang', '亏': 'kui',
    '葵': 'kui', '魁': 'kui', '馈': 'kui', '溃': 'kui', '昆': 'kun',
    '捆': 'kun', '困': 'kun', '扩': 'kuo', '括': 'kuo', '阔': 'kuo',
    '垃': 'la', '拉': 'la', '啦': 'la', '腊': 'la', '辣': 'la',
    '来': 'lai', '赖': 'lai', '兰': 'lan', '拦': 'lan', '栏': 'lan',
    '蓝': 'lan', '篮': 'lan', '览': 'lan', '懒': 'lan', '烂': 'lan',
    '滥': 'lan', '郎': 'lang', '狼': 'lang', '廊': 'lang', '朗': 'lang',
    '浪': 'lang', '捞': 'lao', '劳': 'lao', '牢': 'lao', '老': 'lao',
    '乐': 'le', '雷': 'lei', '泪': 'lei', '类': 'lei', '累': 'lei',
    '冷': 'leng', '愣': 'leng', '厘': 'li', '梨': 'li', '犁': 'li',
    '离': 'li', '理': 'li', '里': 'li', '鲤': 'li', '礼': 'li',
    '李': 'li', '里': 'li', '力': 'li', '历': 'li', '厉': 'li',
    '立': 'li', '丽': 'li', '利': 'li', '例': 'li', '隶': 'li',
    '栗': 'li', '粒': 'li', '俩': 'lia', '连': 'lian', '帘': 'lian',
    '莲': 'lian', '联': 'lian', '廉': 'lian', '脸': 'lian', '练': 'lian',
    '恋': 'lian', '链': 'lian', '良': 'liang', '凉': 'liang', '梁': 'liang',
    '粮': 'liang', '两': 'liang', '亮': 'liang', '谅': 'liang', '辆': 'liang',
    '量': 'liang', '辽': 'liao', '疗': 'liao', '聊': 'liao', '僚': 'liao',
    '了': 'liao', '料': 'liao', '列': 'lie', '劣': 'lie', '烈': 'lie',
    '猎': 'lie', '裂': 'lie', '邻': 'lin', '林': 'lin', '临': 'lin',
    '淋': 'lin', '琳': 'lin', '凛': 'lin', '吝': 'lin', '伶': 'ling',
    '灵': 'ling', '岭': 'ling', '领': 'ling', '令': 'ling', '溜': 'liu',
    '刘': 'liu', '流': 'liu', '留': 'liu', '柳': 'liu', '六': 'liu',
    '龙': 'long', '笼': 'long', '聋': 'long', '隆': 'long', '垄': 'long',
    '拢': 'long', '弄': 'long', '楼': 'lou', '搂': 'lou', '漏': 'lou',
    '陋': 'lou', '卢': 'lu', '芦': 'lu', '炉': 'lu', '鲁': 'lu',
    '陆': 'lu', '录': 'lu', '鹿': 'lu', '碌': 'lu', '路': 'lu',
    '驴': 'lv', '旅': 'lv', '履': 'lv', '律': 'lv', '虑': 'lv',
    '绿': 'lv', '率': 'lv', '乱': 'luan', '掠': 'lve', '略': 'lve',
    '轮': 'lun', '论': 'lun', '罗': 'luo', '螺': 'luo', '洛': 'luo',
    '络': 'luo', '落': 'luo', '妈': 'ma', '麻': 'ma', '马': 'ma',
    '码': 'ma', '蚂': 'ma', '骂': 'ma', '吗': 'ma', '埋': 'mai',
    '买': 'mai', '麦': 'mai', '卖': 'mai', '迈': 'mai', '脉': 'mai',
    '蛮': 'man', '馒': 'man', '满': 'man', '慢': 'man', '漫': 'man',
    '忙': 'mang', '盲': 'mang', '茫': 'mang', '猫': 'mao', '毛': 'mao',
    '矛': 'mao', '茅': 'mao', '茂': 'mao', '冒': 'mao', '帽': 'mao',
    '貌': 'mao', '么': 'me', '没': 'mei', '眉': 'mei', '梅': 'mei',
    '媒': 'mei', '煤': 'mei', '霉': 'mei', '每': 'mei', '美': 'mei',
    '妹': 'mei', '媚': 'mei', '门': 'men', '闷': 'men', '们': 'men',
    '萌': 'meng', '蒙': 'meng', '猛': 'meng', '梦': 'meng', '弥': 'mi',
    '迷': 'mi', '谜': 'mi', '米': 'mi', '秘': 'mi', '密': 'mi',
    '蜜': 'mi', '棉': 'mian', '免': 'mian', '勉': 'mian', '面': 'mian',
    '苗': 'miao', '描': 'miao', '秒': 'miao', '渺': 'miao', '妙': 'miao',
    '庙': 'miao', '灭': 'mie', '民': 'min', '敏': 'min', '名': 'ming',
    '明': 'ming', '鸣': 'ming', '铭': 'ming', '命': 'ming', '谬': 'miu',
    '摸': 'mo', '模': 'mo', '膜': 'mo', '磨': 'mo', '魔': 'mo',
    '抹': 'mo', '末': 'mo', '莫': 'mo', '墨': 'mo', '默': 'mo',
    '沫': 'mo', '母': 'mu', '亩': 'mu', '牡': 'mu', '姆': 'mu',
    '拇': 'mu', '木': 'mu', '目': 'mu', '牧': 'mu', '墓': 'mu',
    '幕': 'mu', '慕': 'mu', '暮': 'mu', '穆': 'mu',
    '拿': 'na', '哪': 'na', '那': 'na', '纳': 'na', '乃': 'nai',
    '奶': 'nai', '耐': 'nai', '男': 'nan', '南': 'nan', '难': 'nan',
    '囊': 'nang', '挠': 'nao', '脑': 'nao', '闹': 'nao', '呢': 'ne',
    '馁': 'nei', '内': 'nei', '嫩': 'nen', '能': 'neng', '尼': 'ni',
    '泥': 'ni', '你': 'ni', '逆': 'ni', '年': 'nian', '念': 'nian',
    '娘': 'niang', '鸟': 'niao', '尿': 'niao', '捏': 'nie', '聂': 'nie',
    '镍': 'nie', '您': 'nin', '宁': 'ning', '凝': 'ning', '牛': 'niu',
    '扭': 'niu', '纽': 'niu', '农': 'nong', '浓': 'nong', '弄': 'nong',
    '奴': 'nu', '努': 'nu', '怒': 'nu', '女': 'nv', '暖': 'nuan',
    '虐': 'nve', '挪': 'nuo', '诺': 'nuo',
    '哦': 'o', '欧': 'ou', '偶': 'ou', '呕': 'ou', '藕': 'ou',
    '怕': 'pa', '拍': 'pai', '排': 'pai', '牌': 'pai', '派': 'pai',
    '攀': 'pan', '盘': 'pan', '判': 'pan', '盼': 'pan', '庞': 'pang',
    '旁': 'pang', '胖': 'pang', '抛': 'pao', '炮': 'pao', '跑': 'pao',
    '泡': 'pao', '陪': 'pei', '培': 'pei', '赔': 'pei', '配': 'pei',
    '佩': 'pei', '喷': 'pen', '盆': 'pen', '朋': 'peng', '棚': 'peng',
    '蓬': 'peng', '膨': 'peng', '捧': 'peng', '碰': 'peng', '批': 'pi',
    '披': 'pi', '疲': 'pi', '皮': 'pi', '匹': 'pi', '屁': 'pi',
    '譬': 'pi', '篇': 'pian', '偏': 'pian', '片': 'pian', '骗': 'pian',
    '漂': 'piao', '飘': 'piao', '票': 'piao', '拼': 'pin', '贫': 'pin',
    '品': 'pin', '聘': 'pin', '乒': 'ping', '平': 'ping', '评': 'ping',
    '凭': 'ping', '瓶': 'ping', '萍': 'ping', '坡': 'po', '泼': 'po',
    '婆': 'po', '破': 'po', '魄': 'po', '剖': 'pou', '扑': 'pu',
    '铺': 'pu', '葡': 'pu', '蒲': 'pu', '普': 'pu', '谱': 'pu',
    '期': 'qi', '欺': 'qi', '漆': 'qi', '齐': 'qi', '奇': 'qi',
    '骑': 'qi', '棋': 'qi', '旗': 'qi', '祈': 'qi', '乞': 'qi',
    '企': 'qi', '启': 'qi', '起': 'qi', '气': 'qi', '弃': 'qi',
    '汽': 'qi', '契': 'qi', '砌': 'qi', '器': 'qi', '掐': 'qia',
    '恰': 'qia', '千': 'qian', '迁': 'qian', '牵': 'qian', '铅': 'qian',
    '谦': 'qian', '签': 'qian', '前': 'qian', '钱': 'qian', '潜': 'qian',
    '浅': 'qian', '遣': 'qian', '欠': 'qian', '枪': 'qiang', '腔': 'qiang',
    '强': 'qiang', '墙': 'qiang', '抢': 'qiang', '悄': 'qiao', '敲': 'qiao',
    '桥': 'qiao', '瞧': 'qiao', '巧': 'qiao', '俏': 'qiao', '翘': 'qiao',
    '切': 'qie', '茄': 'qie', '且': 'qie', '窃': 'qie', '亲': 'qin',
    '侵': 'qin', '秦': 'qin', '琴': 'qin', '勤': 'qin', '青': 'qing',
    '轻': 'qing', '氢': 'qing', '倾': 'qing', '清': 'qing', '晴': 'qing',
    '情': 'qing', '请': 'qing', '庆': 'qing', '穷': 'qiong', '秋': 'qiu',
    '丘': 'qiu', '求': 'qiu', '球': 'qiu', '区': 'qu', '曲': 'qu',
    '驱': 'qu', '屈': 'qu', '趋': 'qu', '取': 'qu', '娶': 'qu',
    '去': 'qu', '趣': 'qu', '圈': 'quan', '全': 'quan', '权': 'quan',
    '泉': 'quan', '拳': 'quan', '犬': 'quan', '劝': 'quan', '缺': 'que',
    '却': 'que', '确': 'que', '雀': 'que', '裙': 'qun', '群': 'qun',
    '然': 'ran', '燃': 'ran', '染': 'ran', '让': 'rang', '饶': 'rao',
    '扰': 'rao', '绕': 'rao', '惹': 're', '热': 're', '人': 'ren',
    '仁': 'ren', '忍': 'ren', '认': 'ren', '任': 'ren', '扔': 'reng',
    '仍': 'reng', '日': 'ri', '荣': 'rong', '容': 'rong', '熔': 'rong',
    '融': 'rong', '柔': 'rou', '肉': 'rou', '如': 'ru', '乳': 'ru',
    '辱': 'ru', '入': 'ru', '软': 'ruan', '锐': 'rui', '瑞': 'rui',
    '润': 'run', '若': 'ruo', '弱': 'ruo',
    '撒': 'sa', '洒': 'sa', '萨': 'sa', '塞': 'sai', '赛': 'sai',
    '三': 'san', '散': 'san', '桑': 'sang', '嗓': 'sang', '丧': 'sang',
    '扫': 'sao', '嫂': 'sao', '色': 'se', '森': 'sen', '僧': 'seng',
    '杀': 'sha', '沙': 'sha', '纱': 'sha', '傻': 'sha', '晒': 'shai',
    '山': 'shan', '删': 'shan', '闪': 'shan', '善': 'shan', '扇': 'shan',
    '伤': 'shang', '商': 'shang', '赏': 'shang', '上': 'shang', '尚': 'shang',
    '烧': 'shao', '稍': 'shao', '少': 'shao', '绍': 'shao', '奢': 'she',
    '赊': 'she', '蛇': 'she', '舍': 'she', '设': 'she', '射': 'she',
    '涉': 'she', '摄': 'she', '申': 'shen', '伸': 'shen', '身': 'shen',
    '深': 'shen', '神': 'shen', '沈': 'shen', '审': 'shen', '婶': 'shen',
    '肾': 'shen', '甚': 'shen', '渗': 'shen', '慎': 'shen', '升': 'sheng',
    '生': 'sheng', '声': 'sheng', '牲': 'sheng', '绳': 'sheng', '省': 'sheng',
    '圣': 'sheng', '胜': 'sheng', '盛': 'sheng', '剩': 'sheng', '尸': 'shi',
    '失': 'shi', '师': 'shi', '狮': 'shi', '施': 'shi', '湿': 'shi',
    '诗': 'shi', '十': 'shi', '石': 'shi', '时': 'shi', '识': 'shi',
    '实': 'shi', '拾': 'shi', '食': 'shi', '史': 'shi', '使': 'shi',
    '始': 'shi', '驶': 'shi', '士': 'shi', '氏': 'shi', '世': 'shi',
    '市': 'shi', '示': 'shi', '式': 'shi', '事': 'shi', '侍': 'shi',
    '势': 'shi', '视': 'shi', '试': 'shi', '饰': 'shi', '室': 'shi',
    '是': 'shi', '适': 'shi', '释': 'shi', '收': 'shou', '手': 'shou',
    '守': 'shou', '首': 'shou', '寿': 'shou', '受': 'shou', '兽': 'shou',
    '售': 'shou', '授': 'shou', '瘦': 'shou', '书': 'shu', '叔': 'shu',
    '殊': 'shu', '梳': 'shu', '舒': 'shu', '疏': 'shu', '输': 'shu',
    '蔬': 'shu', '熟': 'shu', '暑': 'shu', '属': 'shu', '鼠': 'shu',
    '数': 'shu', '术': 'shu', '束': 'shu', '述': 'shu', '树': 'shu',
    '竖': 'shu', '刷': 'shua', '耍': 'shua', '摔': 'shuai', '甩': 'shuai',
    '帅': 'shuai', '拴': 'shuan', '双': 'shuang', '爽': 'shuang', '谁': 'shui',
    '水': 'shui', '睡': 'shui', '顺': 'shun', '说': 'shuo', '硕': 'shuo',
    '丝': 'si', '私': 'si', '思': 'si', '斯': 'si', '撕': 'si',
    '死': 'si', '四': 'si', '寺': 'si', '似': 'si', '饲': 'si',
    '松': 'song', '耸': 'song', '送': 'song', '宋': 'song', '颂': 'song',
    '搜': 'sou', '艘': 'sou', '苏': 'su', '俗': 'su', '素': 'su',
    '速': 'su', '宿': 'su', '诉': 'su', '肃': 'su', '酸': 'suan',
    '蒜': 'suan', '算': 'suan', '虽': 'sui', '随': 'sui', '碎': 'sui',
    '岁': 'sui', '穗': 'sui', '孙': 'sun', '损': 'sun', '笋': 'sun',
    '缩': 'suo', '所': 'suo', '索': 'suo', '锁': 'suo',
    '他': 'ta', '她': 'ta', '它': 'ta', '塌': 'ta', '塔': 'ta',
    '踏': 'ta', '胎': 'tai', '台': 'tai', '抬': 'tai', '太': 'tai',
    '态': 'tai', '泰': 'tai', '贪': 'tan', '摊': 'tan', '滩': 'tan',
    '谈': 'tan', '坦': 'tan', '毯': 'tan', '叹': 'tan', '炭': 'tan',
    '探': 'tan', '碳': 'tan', '汤': 'tang', '塘': 'tang', '堂': 'tang',
    '膛': 'tang', '糖': 'tang', '躺': 'tang', '趟': 'tang', '烫': 'tang',
    '掏': 'tao', '涛': 'tao', '滔': 'tao', '逃': 'tao', '桃': 'tao',
    '陶': 'tao', '淘': 'tao', '讨': 'tao', '套': 'tao', '特': 'te',
    '疼': 'teng', '腾': 'teng', '梯': 'ti', '踢': 'ti', '提': 'ti',
    '题': 'ti', '蹄': 'ti', '体': 'ti', '替': 'ti', '嚏': 'ti',
    '天': 'tian', '添': 'tian', '田': 'tian', '甜': 'tian', '填': 'tian',
    '挑': 'tiao', '条': 'tiao', '跳': 'tiao', '贴': 'tie', '铁': 'tie',
    '厅': 'ting', '听': 'ting', '烃': 'ting', '亭': 'ting', '庭': 'ting',
    '停': 'ting', '挺': 'ting', '艇': 'ting', '通': 'tong', '同': 'tong',
    '铜': 'tong', '童': 'tong', '统': 'tong', '桶': 'tong', '筒': 'tong',
    '痛': 'tong', '偷': 'tou', '头': 'tou', '投': 'tou', '透': 'tou',
    '凸': 'tu', '秃': 'tu', '突': 'tu', '图': 'tu', '徒': 'tu',
    '途': 'tu', '涂': 'tu', '屠': 'tu', '土': 'tu', '吐': 'tu',
    '兔': 'tu', '团': 'tuan', '推': 'tui', '腿': 'tui', '退': 'tui',
    '吞': 'tun', '屯': 'tun', '拖': 'tuo', '托': 'tuo', '脱': 'tuo',
    '驼': 'tuo', '妥': 'tuo', '拓': 'tuo',
    '挖': 'wa', '哇': 'wa', '蛙': 'wa', '瓦': 'wa', '袜': 'wa',
    '歪': 'wai', '外': 'wai', '湾': 'wan', '弯': 'wan', '完': 'wan',
    '玩': 'wan', '顽': 'wan', '挽': 'wan', '晚': 'wan', '碗': 'wan',
    '万': 'wan', '腕': 'wan', '汪': 'wang', '王': 'wang', '网': 'wang',
    '往': 'wang', '忘': 'wang', '望': 'wang', '危': 'wei', '威': 'wei',
    '微': 'wei', '为': 'wei', '围': 'wei', '违': 'wei', '唯': 'wei',
    '维': 'wei', '伟': 'wei', '伪': 'wei', '尾': 'wei', '纬': 'wei',
    '未': 'wei', '位': 'wei', '味': 'wei', '胃': 'wei', '畏': 'wei',
    '喂': 'wei', '慰': 'wei', '卫': 'wei', '温': 'wen', '文': 'wen',
    '纹': 'wen', '闻': 'wen', '稳': 'wen', '问': 'wen', '翁': 'weng',
    '窝': 'wo', '我': 'wo', '沃': 'wo', '卧': 'wo', '握': 'wo',
    '污': 'wu', '屋': 'wu', '无': 'wu', '吴': 'wu', '吾': 'wu',
    '五': 'wu', '午': 'wu', '武': 'wu', '舞': 'wu', '伍': 'wu',
    '侮': 'wu', '捂': 'wu', '物': 'wu', '误': 'wu', '悟': 'wu',
    '雾': 'wu', '夕': 'xi', '西': 'xi', '吸': 'xi', '希': 'xi',
    '息': 'xi', '悉': 'xi', '惜': 'xi', '稀': 'xi', '溪': 'xi',
    '锡': 'xi', '熄': 'xi', '膝': 'xi', '习': 'xi', '席': 'xi',
    '袭': 'xi', '喜': 'xi', '洗': 'xi', '系': 'xi', '戏': 'xi',
    '细': 'xi', '瞎': 'xia', '虾': 'xia', '峡': 'xia', '狭': 'xia',
    '下': 'xia', '夏': 'xia', '吓': 'xia', '掀': 'xian', '先': 'xian',
    '仙': 'xian', '鲜': 'xian', '闲': 'xian', '贤': 'xian', '弦': 'xian',
    '咸': 'xian', '衔': 'xian', '嫌': 'xian', '显': 'xian', '险': 'xian',
    '现': 'xian', '线': 'xian', '限': 'xian', '宪': 'xian', '陷': 'xian',
    '馅': 'xian', '羡': 'xian', '献': 'xian', '乡': 'xiang', '相': 'xiang',
    '香': 'xiang', '箱': 'xiang', '湘': 'xiang', '详': 'xiang', '祥': 'xiang',
    '想': 'xiang', '响': 'xiang', '向': 'xiang', '项': 'xiang', '象': 'xiang',
    '像': 'xiang', '橡': 'xiang', '削': 'xiao', '消': 'xiao', '宵': 'xiao',
    '萧': 'xiao', '硝': 'xiao', '销': 'xiao', '小': 'xiao', '晓': 'xiao',
    '孝': 'xiao', '肖': 'xiao', '笑': 'xiao', '效': 'xiao', '歇': 'xie',
    '协': 'xie', '邪': 'xie', '胁': 'xie', '斜': 'xie', '携': 'xie',
    '鞋': 'xie', '写': 'xie', '泄': 'xie', '卸': 'xie', '屑': 'xie',
    '械': 'xie', '谢': 'xie', '蟹': 'xie', '心': 'xin', '辛': 'xin',
    '欣': 'xin', '新': 'xin', '薪': 'xin', '信': 'xin', '衅': 'xin',
    '星': 'xing', '兴': 'xing', '猩': 'xing', '刑': 'xing', '型': 'xing',
    '形': 'xing', '行': 'xing', '醒': 'xing', '幸': 'xing', '性': 'xing',
    '姓': 'xing', '凶': 'xiong', '兄': 'xiong', '胸': 'xiong', '雄': 'xiong',
    '熊': 'xiong', '休': 'xiu', '修': 'xiu', '羞': 'xiu', '朽': 'xiu',
    '秀': 'xiu', '袖': 'xiu', '绣': 'xiu', '锈': 'xiu', '须': 'xu',
    '虚': 'xu', '需': 'xu', '墟': 'xu', '许': 'xu', '序': 'xu',
    '叙': 'xu', '畜': 'xu', '绪': 'xu', '续': 'xu', '絮': 'xu',
    '蓄': 'xu', '轩': 'xuan', '宣': 'xuan', '悬': 'xuan', '旋': 'xuan',
    '选': 'xuan', '癣': 'xuan', '眩': 'xuan', '靴': 'xue', '薛': 'xue',
    '学': 'xue', '穴': 'xue', '雪': 'xue', '血': 'xue', '勋': 'xun',
    '熏': 'xun', '寻': 'xun', '巡': 'xun', '询': 'xun', '循': 'xun',
    '训': 'xun', '讯': 'xun', '迅': 'xun', '逊': 'xun',
    '压': 'ya', '呀': 'ya', '鸦': 'ya', '鸭': 'ya', '牙': 'ya',
    '崖': 'ya', '雅': 'ya', '亚': 'ya', '咽': 'yan', '烟': 'yan',
    '淹': 'yan', '延': 'yan', '严': 'yan', '言': 'yan', '岩': 'yan',
    '沿': 'yan', '炎': 'yan', '研': 'yan', '盐': 'yan', '颜': 'yan',
    '衍': 'yan', '掩': 'yan', '眼': 'yan', '演': 'yan', '厌': 'yan',
    '艳': 'yan', '燕': 'yan', '验': 'yan', '雁': 'yan', '央': 'yang',
    '秧': 'yang', '扬': 'yang', '羊': 'yang', '阳': 'yang', '氧': 'yang',
    '仰': 'yang', '养': 'yang', '样': 'yang', '邀': 'yao', '腰': 'yao',
    '妖': 'yao', '摇': 'yao', '遥': 'yao', '窑': 'yao', '谣': 'yao',
    '咬': 'yao', '药': 'yao', '要': 'yao', '耀': 'yao', '椰': 'ye',
    '噎': 'ye', '爷': 'ye', '野': 'ye', '业': 'ye', '叶': 'ye',
    '夜': 'ye', '液': 'ye', '一': 'yi', '衣': 'yi', '医': 'yi',
    '依': 'yi', '仪': 'yi', '宜': 'yi', '姨': 'yi', '遗': 'yi',
    '移': 'yi', '疑': 'yi', '乙': 'yi', '已': 'yi', '以': 'yi',
    '蚁': 'yi', '倚': 'yi', '亿': 'yi', '义': 'yi', '艺': 'yi',
    '忆': 'yi', '议': 'yi', '亦': 'yi', '异': 'yi', '役': 'yi',
    '易': 'yi', '疫': 'yi', '益': 'yi', '谊': 'yi', '逸': 'yi',
    '意': 'yi', '溢': 'yi', '毅': 'yi', '翼': 'yi', '因': 'yin',
    '阴': 'yin', '音': 'yin', '姻': 'yin', '银': 'yin', '引': 'yin',
    '饮': 'yin', '隐': 'yin', '印': 'yin', '应': 'ying', '英': 'ying',
    '樱': 'ying', '婴': 'ying', '鹰': 'ying', '迎': 'ying', '盈': 'ying',
    '营': 'ying', '蝇': 'ying', '赢': 'ying', '影': 'ying', '映': 'ying',
    '硬': 'ying', '哟': 'yo', '拥': 'yong', '庸': 'yong', '永': 'yong',
    '咏': 'yong', '泳': 'yong', '勇': 'yong', '涌': 'yong', '用': 'yong',
    '优': 'you', '忧': 'you', '悠': 'you', '尤': 'you', '由': 'you',
    '邮': 'you', '油': 'you', '游': 'you', '友': 'you', '有': 'you',
    '右': 'you', '幼': 'you', '诱': 'you', '又': 'you', '余': 'yu',
    '鱼': 'yu', '娱': 'yu', '渔': 'yu', '愉': 'yu', '愚': 'yu',
    '榆': 'yu', '虞': 'yu', '与': 'yu', '宇': 'yu', '羽': 'yu',
    '雨': 'yu', '语': 'yu', '玉': 'yu', '育': 'yu', '域': 'yu',
    '欲': 'yu', '遇': 'yu', '御': 'yu', '喻': 'yu', '寓': 'yu',
    '裕': 'yu', '愈': 'yu', '誉': 'yu', '豫': 'yu', '元': 'yuan',
    '园': 'yuan', '原': 'yuan', '圆': 'yuan', '援': 'yuan', '缘': 'yuan',
    '源': 'yuan', '远': 'yuan', '怨': 'yuan', '院': 'yuan', '愿': 'yuan',
    '曰': 'yue', '约': 'yue', '月': 'yue', '岳': 'yue', '阅': 'yue',
    '跃': 'yue', '越': 'yue', '云': 'yun', '匀': 'yun', '允': 'yun',
    '孕': 'yun', '运': 'yun', '韵': 'yun', '蕴': 'yun',
    '杂': 'za', '砸': 'za', '灾': 'zai', '栽': 'zai', '宰': 'zai',
    '载': 'zai', '再': 'zai', '在': 'zai', '咱': 'zan', '暂': 'zan',
    '赞': 'zan', '赃': 'zang', '脏': 'zang', '葬': 'zang', '遭': 'zao',
    '糟': 'zao', '早': 'zao', '澡': 'zao', '枣': 'zao', '灶': 'zao',
    '造': 'zao', '噪': 'zao', '燥': 'zao', '躁': 'zao', '则': 'ze',
    '泽': 'ze', '责': 'ze', '择': 'ze', '贼': 'zei', '怎': 'zen',
    '增': 'zeng', '憎': 'zeng', '赠': 'zeng', '扎': 'zha', '眨': 'zha',
    '炸': 'zha', '榨': 'zha', '斋': 'zhai', '宅': 'zhai', '窄': 'zhai',
    '债': 'zhai', '寨': 'zhai', '沾': 'zhan', '粘': 'zhan', '盏': 'zhan',
    '展': 'zhan', '斩': 'zhan', '崭': 'zhan', '占': 'zhan', '战': 'zhan',
    '站': 'zhan', '绽': 'zhan', '张': 'zhang', '章': 'zhang', '彰': 'zhang',
    '漳': 'zhang', '掌': 'zhang', '丈': 'zhang', '杖': 'zhang', '帐': 'zhang',
    '账': 'zhang', '障': 'zhang', '招': 'zhao', '朝': 'zhao', '找': 'zhao',
    '沼': 'zhao', '召': 'zhao', '兆': 'zhao', '照': 'zhao', '罩': 'zhao',
    '遮': 'zhe', '折': 'zhe', '哲': 'zhe', '蛰': 'zhe', '者': 'zhe',
    '锗': 'zhe', '蔗': 'zhe', '这': 'zhe', '浙': 'zhe', '珍': 'zhen',
    '真': 'zhen', '砧': 'zhen', '臻': 'zhen', '诊': 'zhen', '枕': 'zhen',
    '阵': 'zhen', '振': 'zhen', '镇': 'zhen', '震': 'zhen', '争': 'zheng',
    '征': 'zheng', '挣': 'zheng', '睁': 'zheng', '蒸': 'zheng', '整': 'zheng',
    '正': 'zheng', '证': 'zheng', '郑': 'zheng', '政': 'zheng', '之': 'zhi',
    '支': 'zhi', '汁': 'zhi', '芝': 'zhi', '枝': 'zhi', '知': 'zhi',
    '织': 'zhi', '脂': 'zhi', '蜘': 'zhi', '执': 'zhi', '直': 'zhi',
    '值': 'zhi', '职': 'zhi', '植': 'zhi', '殖': 'zhi', '止': 'zhi',
    '只': 'zhi', '旨': 'zhi', '址': 'zhi', '纸': 'zhi', '指': 'zhi',
    '趾': 'zhi', '至': 'zhi', '志': 'zhi', '制': 'zhi', '质': 'zhi',
    '治': 'zhi', '致': 'zhi', '秩': 'zhi', '智': 'zhi', '滞': 'zhi',
    '置': 'zhi', '中': 'zhong', '忠': 'zhong', '终': 'zhong', '钟': 'zhong',
    '衷': 'zhong', '肿': 'zhong', '种': 'zhong', '重': 'zhong', '仲': 'zhong',
    '众': 'zhong', '舟': 'zhou', '周': 'zhou', '洲': 'zhou', '粥': 'zhou',
    '轴': 'zhou', '肘': 'zhou', '帚': 'zhou', '咒': 'zhou', '皱': 'zhou',
    '骤': 'zhou', '珠': 'zhu', '诸': 'zhu', '猪': 'zhu', '蛛': 'zhu',
    '竹': 'zhu', '烛': 'zhu', '逐': 'zhu', '主': 'zhu', '煮': 'zhu',
    '嘱': 'zhu', '瞩': 'zhu', '住': 'zhu', '助': 'zhu', '注': 'zhu',
    '驻': 'zhu', '柱': 'zhu', '祝': 'zhu', '著': 'zhu', '蛀': 'zhu',
    '筑': 'zhu', '铸': 'zhu', '抓': 'zhua', '爪': 'zhua', '拽': 'zhuai',
    '专': 'zhuan', '砖': 'zhuan', '转': 'zhuan', '赚': 'zhuan', '撰': 'zhuan',
    '妆': 'zhuang', '庄': 'zhuang', '装': 'zhuang', '壮': 'zhuang', '状': 'zhuang',
    '撞': 'zhuang', '追': 'zhui', '坠': 'zhui', '缀': 'zhui', '谆': 'zhun',
    '准': 'zhun', '捉': 'zhuo', '拙': 'zhuo', '卓': 'zhuo', '桌': 'zhuo',
    '酌': 'zhuo', '啄': 'zhuo', '着': 'zhuo', '浊': 'zhuo', '兹': 'zi',
    '资': 'zi', '姿': 'zi', '滋': 'zi', '淄': 'zi', '孜': 'zi',
    '紫': 'zi', '仔': 'zi', '籽': 'zi', '滓': 'zi', '子': 'zi',
    '自': 'zi', '字': 'zi', '宗': 'zong', '综': 'zong', '棕': 'zong',
    '踪': 'zong', '总': 'zong', '纵': 'zong', '走': 'zou', '奏': 'zou',
    '揍': 'zou', '租': 'zu', '足': 'zu', '卒': 'zu', '族': 'zu',
    '阻': 'zu', '组': 'zu', '钻': 'zuan', '嘴': 'zui', '最': 'zui',
    '罪': 'zui', '醉': 'zui', '尊': 'zun', '遵': 'zun', '昨': 'zuo',
    '左': 'zuo', '作': 'zuo', '坐': 'zuo', '座': 'zuo', '做': 'zuo',
  };

  /// 常见多音字映射（根据上下文常用读音）
  static const Map<String, String> _polyphoneMap = {
    '长': 'chang', '重': 'zhong', '行': 'xing', '乐': 'le',
    '都': 'dou', '还': 'hai', '发': 'fa', '觉': 'jue',
    '朝': 'chao', '传': 'chuan', '弹': 'dan', '调': 'diao',
    '降': 'jiang', '教': 'jiao', '空': 'kong', '了': 'le',
    '没': 'mei', '模': 'mo', '难': 'nan', '强': 'qiang',
    '省': 'sheng', '数': 'shu', '为': 'wei', '相': 'xiang',
    '兴': 'xing', '应': 'ying', '种': 'zhong', '转': 'zhuan',
    '着': 'zhe', '只': 'zhi', '中': 'zhong', '地': 'de',
    '得': 'de', '的': 'de', '和': 'he',
  };

  // ==========================================================================
  // 汉字转拼音
  // ==========================================================================

  /// 将单个汉字转换为拼音
  ///
  /// 未在映射表中的汉字返回原字符
  static String charToPinyin(String char) {
    if (char.isEmpty) return '';
    // 优先使用多音字映射
    if (_polyphoneMap.containsKey(char)) {
      return _polyphoneMap[char]!;
    }
    // 使用常用字映射
    if (_pinyinMap.containsKey(char)) {
      return _pinyinMap[char]!;
    }
    // 非汉字直接返回
    if (!RegExp(r'[\u4e00-\u9fa5]').hasMatch(char)) {
      return char;
    }
    // 未覆盖的汉字返回原字符
    return char;
  }

  /// 将字符串转换为拼音（空格分隔）
  ///
  /// [withTone] 是否带声调（简易实现不带声调）
  /// [separator] 拼音之间的分隔符
  static String toPinyin(
    String text, {
    String separator = ' ',
    bool withTone = false,
  }) {
    if (text.isEmpty) return '';
    final pinyins = <String>[];
    for (final char in text.split('')) {
      final pinyin = charToPinyin(char);
      if (pinyin.isNotEmpty) {
        pinyins.add(pinyin);
      }
    }
    return pinyins.join(separator);
  }

  /// 将字符串转换为拼音（无空格连接）
  static String toPinyinNoSpace(String text) {
    return toPinyin(text, separator: '');
  }

  // ==========================================================================
  // 首字母提取
  // ==========================================================================

  /// 获取汉字拼音首字母
  static String firstLetter(String char) {
    final pinyin = charToPinyin(char);
    if (pinyin.isEmpty) return '';
    return pinyin[0].toUpperCase();
  }

  /// 获取字符串拼音首字母序列
  ///
  /// 例如："你好" -> "NH"
  static String firstLetters(String text) {
    if (text.isEmpty) return '';
    final letters = <String>[];
    for (final char in text.split('')) {
      final letter = firstLetter(char);
      if (letter.isNotEmpty) {
        letters.add(letter);
      }
    }
    return letters.join();
  }

  /// 获取字符串的第一个拼音首字母
  ///
  /// 例如："你好" -> "N"
  static String firstCharLetter(String text) {
    if (text.isEmpty) return '#';
    final firstChar = text[0];
    final letter = firstLetter(firstChar);
    if (letter.isEmpty) {
      // 非汉字开头
      if (RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
        return firstChar.toUpperCase();
      }
      return '#';
    }
    return letter;
  }

  // ==========================================================================
  // 排序辅助
  // ==========================================================================

  /// 按拼音排序字符串列表
  static List<String> sortByPinyin(List<String> list) {
    final sorted = List<String>.from(list);
    sorted.sort((a, b) {
      final pinyinA = toPinyinNoSpace(a);
      final pinyinB = toPinyinNoSpace(b);
      return pinyinA.compareTo(pinyinB);
    });
    return sorted;
  }

  /// 按拼音首字母分组
  ///
  /// 返回 Map，key 为首字母，value 为该首字母下的字符串列表
  static Map<String, List<String>> groupByFirstLetter(List<String> list) {
    final groups = <String, List<String>>{};
    for (final item in list) {
      final letter = firstCharLetter(item);
      groups.putIfAbsent(letter, () => []);
      groups[letter]!.add(item);
    }
    // 对每个分组内按拼音排序
    groups.forEach((key, value) {
      groups[key] = sortByPinyin(value);
    });
    return groups;
  }

  // ==========================================================================
  // 搜索匹配
  // ==========================================================================

  /// 判断文本是否匹配拼音搜索关键词
  ///
  /// 支持：全拼匹配、首字母匹配、原文本匹配
  static bool matchesPinyin(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) return false;
    final lowerKeyword = keyword.toLowerCase();

    // 原文本匹配
    if (text.toLowerCase().contains(lowerKeyword)) return true;

    // 全拼匹配
    final pinyin = toPinyinNoSpace(text).toLowerCase();
    if (pinyin.contains(lowerKeyword)) return true;

    // 首字母匹配
    final letters = firstLetters(text).toLowerCase();
    if (letters.contains(lowerKeyword)) return true;

    return false;
  }

  /// 获取拼音匹配的高亮位置
  ///
  /// 返回匹配的起始和结束索引列表
  static List<int> findPinyinMatchPositions(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) return [];
    final positions = <int>[];
    final lowerKeyword = keyword.toLowerCase();
    final pinyin = toPinyinNoSpace(text).toLowerCase();

    var index = pinyin.indexOf(lowerKeyword);
    while (index != -1) {
      positions.add(index);
      index = pinyin.indexOf(lowerKeyword, index + 1);
    }
    return positions;
  }

  // ==========================================================================
  // 多音字处理
  // ==========================================================================

  /// 判断是否为多音字
  static bool isPolyphone(String char) {
    return _polyphoneMap.containsKey(char);
  }

  /// 获取多音字的常用读音列表
  static List<String> getPolyphoneReadings(String char) {
    // 常见多音字的多个读音
    const Map<String, List<String>> readings = {
      '长': ['chang', 'zhang'],
      '重': ['zhong', 'chong'],
      '行': ['xing', 'hang'],
      '乐': ['le', 'yue'],
      '都': ['dou', 'du'],
      '还': ['hai', 'huan'],
      '发': ['fa', 'fa'],
      '觉': ['jue', 'jiao'],
      '朝': ['chao', 'zhao'],
      '传': ['chuan', 'zhuan'],
      '弹': ['dan', 'tan'],
      '调': ['diao', 'tiao'],
      '降': ['jiang', 'xiang'],
      '教': ['jiao', 'jiao'],
      '空': ['kong', 'kong'],
      '了': ['le', 'liao'],
      '没': ['mei', 'mo'],
      '模': ['mo', 'mu'],
      '难': ['nan', 'nan'],
      '强': ['qiang', 'qiang', 'jiang'],
      '省': ['sheng', 'xing'],
      '数': ['shu', 'shu', 'shuo'],
      '为': ['wei', 'wei'],
      '相': ['xiang', 'xiang'],
      '兴': ['xing', 'xing'],
      '应': ['ying', 'ying'],
      '种': ['zhong', 'zhong'],
      '转': ['zhuan', 'zhuan'],
      '着': ['zhe', 'zhao', 'zhuo'],
      '只': ['zhi', 'zhi'],
      '中': ['zhong', 'zhong'],
      '地': ['de', 'di'],
      '得': ['de', 'dei', 'de'],
      '的': ['de', 'di', 'di'],
      '和': ['he', 'he', 'huo', 'huo', 'hu'],
    };
    return readings[char] ?? [charToPinyin(char)];
  }
}
