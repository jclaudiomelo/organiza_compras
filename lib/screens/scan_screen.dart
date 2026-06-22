import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import '../controllers/purchase_controller.dart';
import 'package:flutter/services.dart';
import '../services/sefaz_parser.dart';
import '../models/purchase.dart';

class ScanScreen extends StatefulWidget {
  final PurchaseController controller;

  const ScanScreen({super.key, required this.controller});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _processScannedCode(rawValue);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String code) async {
    // 1. Check if the access key is already imported before making any requests or opening WebView
    final accessKey = SefazParser.getAccessKeyFromUrl(code);
    if (accessKey != null) {
      final alreadyExists = widget.controller.purchases.any((p) => p.accessKey == accessKey);
      if (alreadyExists) {
        _scannerController.stop();
        setState(() {
          _isProcessing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta nota fiscal já foi importada anteriormente!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _scannerController.start();
        }
        return;
      }
    }

    // Check if it's a demo QR Code or mock scan request
    if (code.toLowerCase().startsWith('demo')) {
      setState(() {
        _isProcessing = true;
      });
      _scannerController.stop();
      try {
        final purchase = await SefazParser.parseQRCode(code);
        if (mounted) {
          _showConfirmSaveBottomSheet(purchase);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao analisar QR Code de simulação: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _isProcessing = false;
          });
          _scannerController.start();
        }
      }
    } else if (!code.startsWith('http') && accessKey != null) {
      // Scanned a pure 44-digit key (like a barcode). Route to the correct state portal URL
      _scannerController.stop();
      final url = SefazParser.getSefazUrl(accessKey, widget.controller.defaultState);
      _openWebViewPortal(url);
    } else if (code.startsWith('http')) {
      // It's a real SEFAZ URL! Stop camera and open WebView to handle CAPTCHAs
      _scannerController.stop();
      _openWebViewPortal(code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código escaneado inválido ou não reconhecido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openWebViewPortal(String url) {
    setState(() {
      _isProcessing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        InAppWebViewController? webViewController;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog.fullscreen(
              key: const Key('webview_dialog'),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: const Color(0xFF16161A),
                    title: const Text('Consultando Nota', style: TextStyle(color: Colors.white, fontSize: 16)),
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        setState(() {
                          _isProcessing = false;
                        });
                        _scannerController.start();
                      },
                    ),
                    actions: [
                      if (isSaving)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: webViewController == null
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(dialogContext);
                                      final screenNavigator = Navigator.of(this.context);
                                      
                                      setStateDialog(() {
                                        isSaving = true;
                                      });
                                      try {
                                        final currentUrl = (await webViewController!.getUrl())?.toString() ?? url;
                                        final htmlContent = await webViewController!.getHtml() ?? '';
                                        
                                        // Parse the HTML content
                                        final purchase = SefazParser.parseHtmlContent(htmlContent, currentUrl);
                                        
                                        // Check duplicates
                                        final alreadyExists = widget.controller.purchases.any((p) => p.accessKey == purchase.accessKey);
                                        if (alreadyExists) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('Esta nota fiscal já foi importada anteriormente!'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          setStateDialog(() {
                                            isSaving = false;
                                          });
                                          return;
                                        }

                                        // Save to database
                                        final success = await widget.controller.savePurchase(purchase);
                                        if (success) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('Compra importada e salva com sucesso!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          navigator.pop();
                                          screenNavigator.pop(true);
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(widget.controller.errorMessage ?? 'Erro ao salvar a compra.'),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                          setStateDialog(() {
                                            isSaving = false;
                                          });
                                        }
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Não foi possível ler os itens da nota ainda: $e'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        setStateDialog(() {
                                          isSaving = false;
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Salvar', style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurpleAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(url)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                      ),
                      onReceivedServerTrustAuthRequest: (controller, challenge) async {
                        return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                      },
                      onWebViewCreated: (controller) {
                        setStateDialog(() {
                          webViewController = controller;
                        });
                      },
                      onLoadStop: (controller, loadedUrl) async {
                        // 1. Inject Auto-fill script & auto-click tab or query button if no captcha
                        await controller.evaluateJavascript(source: """
                          (function() {
                            try {
                              var urlParams = new URLSearchParams(window.location.search);
                              var key = urlParams.get('chave') || urlParams.get('chNFe') || urlParams.get('p') || urlParams.get('chKey');
                              if (!key) {
                                var match = window.location.href.match(/\\d{44}/);
                                if (match) key = match[0];
                              }
                              
                              if (key && key.length === 44) {
                                var inputs = document.querySelectorAll('input[type="text"], input[type="number"], input:not([type])');
                                var keyInput = null;
                                for (var i = 0; i < inputs.length; i++) {
                                  var input = inputs[i];
                                  var id = (input.id || '').toLowerCase();
                                  var name = (input.name || '').toLowerCase();
                                  var placeholder = (input.placeholder || '').toLowerCase();
                                  var maxlen = input.getAttribute('maxlength');
                                  
                                  if (maxlen === '44' || maxlen === '48' || 
                                      id.includes('chave') || name.includes('chave') || placeholder.includes('chave') || 
                                      id.includes('chnfe') || name.includes('chnfe') || placeholder.includes('chnfe') || 
                                      id.includes('nfe') || name.includes('nfe') || placeholder.includes('nota')) {
                                    keyInput = input;
                                    break;
                                  }
                                }
                                
                                if (keyInput) {
                                  var cleanVal = (keyInput.value || '').replace(/\\D/g, '');
                                  if (cleanVal.length !== 44) {
                                    keyInput.value = key;
                                    keyInput.dispatchEvent(new Event('input', { bubbles: true }));
                                    keyInput.dispatchEvent(new Event('change', { bubbles: true }));
                                    
                                    var hasCaptcha = document.querySelector('img[src*="captcha"], img[id*="captcha"], iframe[src*="recaptcha"], iframe[src*="hcaptcha"], div[class*="captcha"], div[id*="captcha"]') !== null;
                                    
                                    if (!hasCaptcha) {
                                      var buttons = document.querySelectorAll('input[type="submit"], button, input[type="button"], a.btn');
                                      for (var j = 0; j < buttons.length; j++) {
                                        var btn = buttons[j];
                                        var btnText = (btn.value || btn.innerText || btn.id || '').toLowerCase();
                                        if (btnText.includes('consultar') || btnText.includes('pesquisar') || btnText.includes('buscar') || btnText.includes('enviar') || btnText.includes('avançar') || btnText.includes('ok')) {
                                          btn.click();
                                          break;
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                              
                              var links = document.querySelectorAll('a, span, li, td');
                              for (var i = 0; i < links.length; i++) {
                                var linkText = (links[i].innerText || '').toLowerCase().trim();
                                if (linkText === 'produtos/serviços' || linkText === 'produtos e serviços' || linkText === 'itens' || linkText === 'itens da nota' || linkText === 'produtos / serviços') {
                                  links[i].click();
                                }
                              }
                            } catch (e) {
                              console.log('Autofill error: ' + e);
                            }
                          })();
                        """);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConfirmSaveBottomSheet(Purchase purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Confirmar Nova Nota',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isProcessing = false;
                          });
                          _scannerController.start();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                
                // Purchase details preview
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Store Name & Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24242B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              purchase.storeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateFormat.format(purchase.date),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${purchase.items.length} itens',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  currencyFormat.format(purchase.totalValue),
                                  style: const TextStyle(
                                    color: Colors.deepPurpleAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(
                        'Itens da Nota',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // List of items
                      ...purchase.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity.toStringAsFixed(item.unit == 'KG' ? 3 : 0)} ${item.unit} x ${currencyFormat.format(item.unitPrice)}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.totalPrice),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                // Confirm / Cancel Action Buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _isProcessing = false;
                            });
                            _scannerController.start();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Descartar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final bottomSheetNavigator = Navigator.of(context);
                            final screenNavigator = Navigator.of(this.context);
                            
                            bottomSheetNavigator.pop(); // Close bottom sheet
                            
                            // Save to database
                            setState(() {
                              _isProcessing = true;
                            });
                            
                            final success = await widget.controller.savePurchase(purchase);
                            
                            if (mounted) {
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Compra importada e salva com sucesso!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                screenNavigator.pop(true);
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(widget.controller.errorMessage ?? 'Erro ao salvar a compra.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                setState(() {
                                  _isProcessing = false;
                                });
                                _scannerController.start();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCheckingPermission
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : Stack(
              children: [
                if (_hasPermission)
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      key: const Key('permission_request_view'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Permissão de Câmera Necessária',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Precisamos da sua câmera para ler o QR Code da NFC-e no cupom fiscal.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _checkPermission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Permitir Acesso'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Scanner HUD Overlay
                if (_hasPermission && !_isProcessing)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ScannerOverlayPainter(),
                    ),
                  ),

                // Processing UI
                if (_isProcessing)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.deepPurple),
                          SizedBox(height: 20),
                          Text(
                            'Buscando dados na SEFAZ...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Carregando itens e valores da compra',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;

  ScannerOverlayPainter({this.borderColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.4,
    );

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(16))),
    );

    canvas.drawPath(path, paint);

    // Draw borders
    final left = holeRect.left;
    final top = holeRect.top;
    final right = holeRect.right;
    final bottom = holeRect.bottom;

    final linePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 30.0;

    // Top Left Corner
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), linePaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), linePaint);

    // Top Right Corner
    canvas.drawLine(Offset(right, top), Offset(right - cornerLength, top), linePaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), linePaint);

    // Bottom Left Corner
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), linePaint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerLength), linePaint);

    // Bottom Right Corner
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLength, bottom), linePaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AccessKeyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Keep only numbers
    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncatedText = cleanText.substring(0, cleanText.length > 44 ? 44 : cleanText.length);
    
    final buffer = StringBuffer();
    for (int i = 0; i < truncatedText.length; i++) {
      buffer.write(truncatedText[i]);
      final index = i + 1;
      if (index % 4 == 0 && index != truncatedText.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
