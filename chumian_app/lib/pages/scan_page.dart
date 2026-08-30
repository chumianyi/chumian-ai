import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  String? _scannedCode;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code != _scannedCode) {
        setState(() => _scannedCode = code);
        HapticFeedback.vibrate();
        _controller.stop();
        _showResultDialog(code);
        break;
      }
    }
  }

  void _showResultDialog(String code) {
    final isUrl = Uri.tryParse(code)?.hasScheme == true && (code.startsWith('http://') || code.startsWith('https://'));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('扫描成功')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('扫描内容:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(code, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
            },
            child: const Text('复制'),
          ),
          if (isUrl)
            TextButton(
              onPressed: () async {
                await launchUrl(Uri.parse(code), mode: LaunchMode.externalApplication);
              },
              child: const Text('打开链接'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _scannedCode = null);
              _controller.start();
            },
            child: const Text('继续扫描'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('完成')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫码'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // 扫描框
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // 四角
                  Positioned(left: -2, top: -2, child: _corner(Alignment.topLeft)),
                  Positioned(right: -2, top: -2, child: _corner(Alignment.topRight)),
                  Positioned(left: -2, bottom: -2, child: _corner(Alignment.bottomLeft)),
                  Positioned(right: -2, bottom: -2, child: _corner(Alignment.bottomRight)),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 80, left: 0, right: 0,
            child: Center(child: Text('将二维码/条形码放入框内', style: TextStyle(color: Colors.white70, fontSize: 14))),
          ),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: alignment.y < 0 ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
          bottom: alignment.y > 0 ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
          left: alignment.x < 0 ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
          right: alignment.x > 0 ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
