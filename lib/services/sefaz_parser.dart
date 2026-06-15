import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import '../models/purchase.dart';
import '../models/purchase_item.dart';

class SefazParser {
  static String? getAccessKeyFromUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      final p = uri.queryParameters['p'] ?? uri.queryParameters['chNFe'] ?? uri.queryParameters['chave'];
      if (p != null) {
        final regExp = RegExp(r'\d{44}');
        final match = regExp.firstMatch(p);
        if (match != null) return match.group(0);
      }
      final regExp = RegExp(r'\d{44}');
      final match = regExp.firstMatch(url);
      if (match != null) return match.group(0);
    } catch (_) {}
    return null;
  }

  static final Map<String, String> _ufCodeToAbbreviation = {
    '11': 'RO', '12': 'AC', '13': 'AM', '14': 'RR', '15': 'PA',
    '16': 'AP', '17': 'TO', '21': 'MA', '22': 'PI', '23': 'CE',
    '24': 'RN', '25': 'PB', '26': 'PE', '27': 'AL', '28': 'SE',
    '29': 'BA', '31': 'MG', '32': 'ES', '33': 'RJ', '35': 'SP',
    '41': 'PR', '42': 'SC', '43': 'RS', '50': 'MS', '51': 'MT',
    '52': 'GO', '53': 'DF',
  };

  static final Map<String, String> _stateToSefazUrlTemplate = {
    'AC': 'https://www.sefaz.ac.gov.br/nfce/consulta?p={key}',
    'AL': 'http://www.sefaz.al.gov.br/nfce/consulta?p={key}',
    'AP': 'https://www.sefaz.ap.gov.br/nfce/consulta?p={key}',
    'AM': 'https://sistemas.sefaz.am.gov.br/nfce-consulta/view/consultanfce/consulta.sefaz?p={key}',
    'BA': 'https://sistemas.sefaz.ba.gov.br/nfce/portal/consultanfce.aspx?p={key}',
    'CE': 'http://nfce.sefaz.ce.gov.br/pages/consultaNota.jsf?chave={key}',
    'DF': 'https://dec.fazenda.df.gov.br/ConsultarNFCe.aspx?p={key}',
    'ES': 'https://www.sefaz.es.gov.br/nfce/consulta?p={key}',
    'GO': 'https://giga.sefaz.go.gov.br/nfce/portal/consultanfce.aspx?p={key}',
    'MA': 'https://sistemas1.sefaz.ma.gov.br/nfce/consulta?p={key}',
    'MT': 'https://www.sefaz.mt.gov.br/nfce/consultanfce?p={key}',
    'MS': 'https://www.dfe.ms.gov.br/nfce/consulta?p={key}',
    'MG': 'https://portalsped.fazenda.mg.gov.br/portalnfce/sistema/consulta.xhtml?p={key}',
    'PA': 'https://app.sefa.pa.gov.br/nfce/consulta?p={key}',
    'PB': 'https://www.sefaz.pb.gov.br/nfce/consulta?p={key}',
    'PR': 'http://www.fazenda.pr.gov.br/nfce/consulta?p={key}',
    'PE': 'https://nfce.sefaz.pe.gov.br/nfce/consulta?p={key}',
    'PI': 'https://www.sefaz.pi.gov.br/nfce/consulta?p={key}',
    'RJ': 'https://www4.fazenda.rj.gov.br/consultaNFCe/QRCode?p={key}',
    'RN': 'https://set.rn.gov.br/nfce/consulta?p={key}',
    'RS': 'https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p={key}',
    'RO': 'https://www.sefaz.ro.gov.br/nfce/consulta?p={key}',
    'RR': 'https://www.sefaz.rr.gov.br/nfce/consulta?p={key}',
    'SC': 'https://sistemas.sef.sc.gov.br/nfce/portal/consultanfce.aspx?p={key}',
    'SP': 'https://www.nfce.fazenda.sp.gov.br/NFCePortal/Paginas/ConsultaPublica.aspx?chNFe={key}',
    'SE': 'http://www.sefaz.se.gov.br/nfce/consulta?p={key}',
    'TO': 'https://www.sefaz.to.gov.br/nfce/consulta?p={key}',
  };

  static String getSefazUrl(String key, String defaultState) {
    final cleanKey = key.replaceAll(' ', '').trim();
    String targetState = defaultState;

    if (cleanKey.length >= 2) {
      final prefix = cleanKey.substring(0, 2);
      final detectedState = _ufCodeToAbbreviation[prefix];
      if (detectedState != null) {
        targetState = detectedState;
      }
    }

    if (targetState == 'CE' && cleanKey.length >= 22) {
      final model = cleanKey.substring(20, 22);
      if (model == '55') {
        return 'https://nfe.sefaz.ce.gov.br/pages/consultaNotaFiscal.xhtml?chave=$cleanKey';
      } else {
        return 'http://nfce.sefaz.ce.gov.br/pages/consultaNota.jsf?chave=$cleanKey';
      }
    }

    final template = _stateToSefazUrlTemplate[targetState] ??
                     _stateToSefazUrlTemplate['SC']!;

    return template.replaceAll('{key}', cleanKey);
  }

  // Parses raw text from QR Code scan. Usually a URL.
  // Returns a full Purchase object by scraping the SEFAZ page,
  // or a mock Purchase object if it is a simulated/demo scan.
  static Future<Purchase> parseQRCode(String qrCodeUrl) async {
    final cleanUrl = qrCodeUrl.trim();
    debugPrint('SefazParser: Scanned URL = $cleanUrl');

    // Check if it's a demo QR Code or mock scan request
    if (cleanUrl.toLowerCase().startsWith('demo') || !cleanUrl.startsWith('http')) {
      return _generateMockPurchase(cleanUrl);
    }

    try {
      // 1. Fetch HTML from SEFAZ with standard browser headers to avoid firewall blocks
      final response = await http.get(
        Uri.parse(cleanUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
          'Connection': 'keep-alive',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao conectar com a SEFAZ (Status: ${response.statusCode})');
      }

      // Read response body. SEFAZ portals often use ISO-8859-1 (Latin1) encoding
      String htmlBody;
      try {
        htmlBody = const Latin1Decoder().convert(response.bodyBytes);
      } catch (_) {
        htmlBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      }

      return parseHtmlContent(htmlBody, cleanUrl);
    } catch (e) {
      // Fallback: If network fails or layout changes, we can try to guess from parameters or throw.
      // For a better user experience in this prototype, let's log the error and rethrow it
      // so the UI can show a fallback screen or option to import a demo note.
      debugPrint('SefazParser Error: $e');
      rethrow;
    }
  }

  // Extracts data from SEFAZ HTML structure
  static Purchase parseHtmlContent(String htmlContent, String sourceUrl) {
    final document = parser.parse(htmlContent);

    // 1. Extract Access Key (Chave de Acesso)
    // Often formatted inside a span/div as "3119 0812 3456 ..." or in the URL itself
    String accessKey = _extractAccessKey(document, sourceUrl);

    // 2. Extract Store Name
    String storeName = _extractStoreName(document);

    // 3. Extract Purchase Date
    DateTime purchaseDate = _extractPurchaseDate(document);

    // 4. Extract Items
    List<PurchaseItem> items = [];
    
    // Look for rows inside the standard tabResult table (national standard layout)
    final rows = document.querySelectorAll('#tabResult tr, .table tr');
    
    if (rows.isNotEmpty) {
      for (var row in rows) {
        final item = _parseRow(row);
        if (item != null) {
          items.add(item);
        }
      }
    }

    // If no items found, try fallback table selectors
    if (items.isEmpty) {
      final allRows = document.querySelectorAll('tr');
      for (var row in allRows) {
        final item = _parseRow(row);
        if (item != null) {
          items.add(item);
        }
      }
    }

    // If still no items, try regex parsing of the page text (very robust fallback for SEFAZ SC and others)
    if (items.isEmpty) {
      final text = document.body?.text ?? '';
      final regExp = RegExp(
        r'([^\n\(\)]+)\(Código:\s*(\d+)\s*\)[\s\n\t]+Qtde\.:\s*([\d,.]+)\s+UN:\s*(\w+)[\s\t]+Vl\.\s*Unit\.:\s*([\d,.]+)[\s\t]+Vl\.\s*Total[\s\n\t]+([\d,.]+)',
        caseSensitive: false,
      );

      final matches = regExp.allMatches(text);
      for (final match in matches) {
        final name = match.group(1)!.trim().toUpperCase();
        final qtyStr = match.group(3)!.replaceAll(',', '.');
        final unit = match.group(4)!.trim().toUpperCase();
        final unitPriceStr = match.group(5)!.replaceAll('.', '').replaceAll(',', '.');
        final totalPriceStr = match.group(6)!.replaceAll('.', '').replaceAll(',', '.');

        final quantity = double.tryParse(qtyStr) ?? 1.0;
        final unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
        final totalPrice = double.tryParse(totalPriceStr) ?? 0.0;

        final category = categorizeItem(name);

        items.add(
          PurchaseItem(
            name: name,
            quantity: quantity,
            unit: unit,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            category: category,
          ),
        );
      }
    }

    // 5. Extract Total Value
    double totalValue = _extractTotalValue(document);
    
    if (totalValue == 0) {
      final text = document.body?.text ?? '';
      final totalRegExp = RegExp(r'(?:Valor a pagar|Valor total|Total da nota)\s*R\$:\s*([\d,.]+)', caseSensitive: false);
      final match = totalRegExp.firstMatch(text);
      if (match != null) {
        final cleanVal = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
        totalValue = double.tryParse(cleanVal) ?? 0.0;
      }
    }
    
    // If we parsed items but total value is 0, sum item total prices
    if (totalValue == 0 && items.isNotEmpty) {
      totalValue = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    }

    if (items.isEmpty) {
      final text = document.body?.text ?? '';
      final sampleText = text.substring(0, text.length > 120 ? 120 : text.length).trim().replaceAll('\n', ' ');
      debugPrint('HTML Text Sample: $sampleText');
      throw Exception('Format Error. Page text start: "$sampleText..."');
    }

    return Purchase(
      accessKey: accessKey,
      storeName: storeName,
      date: purchaseDate,
      totalValue: totalValue,
      items: items,
    );
  }

  static String _extractAccessKey(Document doc, String url) {
    // Try URL first (p parameter or Chave parameter)
    try {
      final uri = Uri.parse(url);
      final p = uri.queryParameters['p'] ?? uri.queryParameters['chNFe'];
      if (p != null) {
        // Extract the first 44 digits
        final regExp = RegExp(r'\d{44}');
        final match = regExp.firstMatch(p);
        if (match != null) return match.group(0)!;
      }
    } catch (_) {}

    // Try HTML search
    final keyElement = doc.querySelector('.chave, #chave, .txtChave, #lblChave');
    if (keyElement != null) {
      final text = keyElement.text.replaceAll(RegExp(r'\D'), '');
      if (text.length == 44) return text;
    }

    // Fallback regex over whole HTML
    final regExp = RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\b');
    final match = regExp.firstMatch(doc.body?.text ?? '');
    if (match != null) {
      return match.group(0)!.replaceAll(' ', '');
    }

    // Generate random if completely missing (should not happen for valid NFC-e)
    return DateTime.now().millisecondsSinceEpoch.toString().padRight(44, '0');
  }

  static String _extractStoreName(Document doc) {
    // Common elements for store name in SEFAZ
    final selectors = [
      '.txtTopo',
      '#Emitente .nome',
      '.nomeEmitente',
      '#lblRazaoSocial',
      'td.txtTopo',
      '.header .title',
      'h2',
    ];

    for (var selector in selectors) {
      final element = doc.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        return element.text.trim().toUpperCase();
      }
    }

    return 'ESTABELECIMENTO COMERCIAL';
  }

  static DateTime _extractPurchaseDate(Document doc) {
    // Try to find dates in standard format dd/mm/yyyy hh:mm:ss
    final regExp = RegExp(r'(\d{2}/\d{2}/\d{4})\s?(\d{2}:\d{2}:\d{2})?');
    final text = doc.body?.text ?? '';
    final match = regExp.firstMatch(text);

    if (match != null) {
      final dateStr = match.group(1)!;
      final timeStr = match.group(2) ?? '12:00:00';
      
      final parts = dateStr.split('/');
      final timeParts = timeStr.split(':');
      
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
          int.parse(timeParts[0]), // hour
          int.parse(timeParts[1]), // minute
          int.parse(timeParts.length > 2 ? timeParts[2] : '0'), // second
        );
      }
    }

    return DateTime.now();
  }

  static double _extractTotalValue(Document doc) {
    final selectors = [
      '.totalNFe .txtVal',
      '#valTotal',
      '.valorTotal',
      '#lblValorTotal',
      'td.txtVal',
    ];

    for (var selector in selectors) {
      final elements = doc.querySelectorAll(selector);
      for (var element in elements) {
        final text = element.text.trim();
        if (text.isNotEmpty) {
          final cleanVal = text.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
          final val = double.tryParse(cleanVal);
          if (val != null && val > 0) return val;
        }
      }
    }

    // Try finding "Valor total" label in table cells and grabbing the next sibling cell
    final tables = doc.querySelectorAll('td, th, span');
    for (var element in tables) {
      final text = element.text.toLowerCase();
      if (text.contains('valor total') || text.contains('total da nota') || text.contains('valor a pagar')) {
        final parent = element.parent;
        if (parent != null) {
          final nextElements = parent.querySelectorAll('td, span');
          for (var next in nextElements) {
            if (next != element) {
              final cleanVal = next.text.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
              final val = double.tryParse(cleanVal);
              if (val != null && val > 0) return val;
            }
          }
        }
      }
    }

    return 0.0;
  }

  static PurchaseItem? _parseRow(Element row) {
    // Standard layout elements (NF-e/NFC-e query pattern)
    // Product Name
    final nameEl = row.querySelector('.txtTit, .nomeItem, td:nth-child(1) span.txtTit');
    if (nameEl == null) return null;

    final name = nameEl.text.trim().toUpperCase();
    if (name.isEmpty) return null;



    // Quantity
    final qtyEl = row.querySelector('.RQty, td:nth-child(2)');
    double quantity = 1.0;
    if (qtyEl != null) {
      final text = qtyEl.text.toLowerCase().replaceAll('qtde:', '').replaceAll('qtd:', '').trim();
      final cleanVal = text.split(' ').first.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
      quantity = double.tryParse(cleanVal) ?? 1.0;
    }

    // Unit
    final unitEl = row.querySelector('.RUN, td:nth-child(3)');
    String unit = 'UN';
    if (unitEl != null) {
      final text = unitEl.text.toUpperCase().replaceAll('UNIDADE:', '').replaceAll('UN:', '').trim();
      final words = text.split(' ').where((w) => w.isNotEmpty).toList();
      if (words.isNotEmpty) {
        unit = words.last; // typical output: "UN" or "KG"
        if (unit.length > 4) unit = 'UN';
      }
    }

    // Unit Price
    final priceEl = row.querySelector('.RValUnit, td:nth-child(4)');
    double unitPrice = 0.0;
    if (priceEl != null) {
      final text = priceEl.text.toLowerCase().replaceAll('vl. unit.:', '').replaceAll('vlr. unit:', '').trim();
      final cleanVal = text.split(' ').first.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
      unitPrice = double.tryParse(cleanVal) ?? 0.0;
    }

    // Total Price
    final totalEl = row.querySelector('.valor, .txtVal, td:nth-child(5)');
    double totalPrice = 0.0;
    if (totalEl != null) {
      final cleanVal = totalEl.text.replaceAll('.', '').replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');
      totalPrice = double.tryParse(cleanVal) ?? 0.0;
    }

    if (totalPrice == 0.0 && unitPrice > 0) {
      totalPrice = quantity * unitPrice;
    }
    if (unitPrice == 0.0 && totalPrice > 0 && quantity > 0) {
      unitPrice = totalPrice / quantity;
    }

    final category = categorizeItem(name);

    return PurchaseItem(
      name: name,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      category: category,
    );
  }

  // Automatic categorizer based on keywords
  static String categorizeItem(String productName) {
    final name = productName.toLowerCase();

    // Food (Alimentação)
    if (_matches(name, [
      'leite', 'pao', 'pão', 'arroz', 'feijao', 'feijão', 'macarrao', 'carne', 'frango', 'peixe',
      'queijo', 'presunto', 'biscoito', 'bolacha', 'oleo', 'sal', 'acucar', 'açúcar', 'cafe', 'café',
      'iogurte', 'manteiga', 'banana', 'maca', 'maçã', 'tomate', 'cebola', 'alho', 'batata',
      'farinha', 'molho', 'oleo', 'azeite', 'ovos', 'ovo', 'chocolate', 'sorvete', 'doce', 'pizz'
    ])) {
      return 'Alimentação';
    }

    // Drinks (Bebidas)
    if (_matches(name, [
      'cerveja', 'refrigerante', 'coca', 'fanta', 'guarana', 'guaraná', 'suco', 'agua', 'água',
      'vinho', 'vodka', 'energetico', 'energético', 'chopp', 'rum', 'whisky', 'tubaína'
    ])) {
      return 'Bebidas';
    }

    // Cleaning (Limpeza)
    if (_matches(name, [
      'amaciante', 'sabao', 'sabão', 'detergente', 'desinfetante', 'agua sanitaria', 'cloro',
      'esponja', 'limpador', 'lustra', 'alvejante', 'sabao em po', 'sabonete liq', 'veja', 'omom'
    ])) {
      return 'Limpeza';
    }

    // Hygiene (Higiene)
    if (_matches(name, [
      'sabonete', 'shampoo', 'xampu', 'condicionador', 'pasta de dente', 'creme dental',
      'fio dental', 'desodorante', 'papel higienico', 'papel higiênico', 'escova', 'gilete',
      'lamina', 'absorvente', 'fralda', 'cotonete', 'algodao'
    ])) {
      return 'Higiene';
    }

    return 'Outros';
  }

  static bool _matches(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  // Generates dummy data for quick testing and demonstration
  static Purchase _generateMockPurchase(String code) {
    final rand = Random();
    final stores = [
      'SUPERMERCADO ANGELONI SC',
      'GIASSI SUPERMERCADOS',
      'BISTEK SUPERMERCADOS',
      'FORT ATACADISTA',
      'MILIUM TEM DE TUDO'
    ];
    
    final store = stores[rand.nextInt(stores.length)];
    final accessKey = code.replaceAll(RegExp(r'\D'), '').padRight(44, '0').substring(0, 44);
    
    final mockItemsPool = [
      {'name': 'LEITE INTEGRAL PARMALAT 1L', 'price': 5.49, 'unit': 'UN', 'cat': 'Alimentação'},
      {'name': 'PAO DE FORMA INTEGRAL WICKBOLD', 'price': 8.99, 'unit': 'UN', 'cat': 'Alimentação'},
      {'name': 'ARROZ TIO JOAO TIPO 1 5KG', 'price': 27.90, 'unit': 'UN', 'cat': 'Alimentação'},
      {'name': 'FEIJAO PRETO CALDAO 1KG', 'price': 7.89, 'unit': 'UN', 'cat': 'Alimentação'},
      {'name': 'CAFE MELITTA REGULAR VACUO 500G', 'price': 18.50, 'unit': 'UN', 'cat': 'Alimentação'},
      {'name': 'CERVEJA SPATEN LATA 350ML', 'price': 4.19, 'unit': 'UN', 'cat': 'Bebidas'},
      {'name': 'REFRIGERANTE COCA COLA PET 2L', 'price': 9.99, 'unit': 'UN', 'cat': 'Bebidas'},
      {'name': 'AGUA MINERAL SEM GAS DA GUARDA 500ML', 'price': 2.20, 'unit': 'UN', 'cat': 'Bebidas'},
      {'name': 'DETERGENTE YPE NEUTRO 500ML', 'price': 2.49, 'unit': 'UN', 'cat': 'Limpeza'},
      {'name': 'AMACIANTE DOWNY BRISA DE VERAO 1L', 'price': 16.90, 'unit': 'UN', 'cat': 'Limpeza'},
      {'name': 'SABONETE DOVE ORIGINAL 90G', 'price': 3.79, 'unit': 'UN', 'cat': 'Higiene'},
      {'name': 'CREME DENTAL COLGATE TOTAL 12 90G', 'price': 6.49, 'unit': 'UN', 'cat': 'Higiene'},
      {'name': 'PAPEL HIGIENICO NEVE F. DUPLA 12UN', 'price': 21.90, 'unit': 'UN', 'cat': 'Higiene'},
      {'name': 'LAMPADA LED TASCHIBRA 9W', 'price': 12.50, 'unit': 'UN', 'cat': 'Outros'},
    ];

    // Select random number of items (4 to 9)
    final numItems = rand.nextInt(6) + 4;
    List<PurchaseItem> items = [];
    double total = 0.0;

    // Shuffle pool to pick random items
    final shuffledPool = List.of(mockItemsPool)..shuffle(rand);

    for (int i = 0; i < numItems; i++) {
      final poolItem = shuffledPool[i];
      final qty = (poolItem['cat'] == 'Alimentação' && poolItem['name'].toString().contains('5KG'))
          ? 1.0
          : (rand.nextInt(3) + 1).toDouble();
      
      final unitPrice = poolItem['price'] as double;
      final itemTotal = qty * unitPrice;
      total += itemTotal;

      items.add(
        PurchaseItem(
          name: poolItem['name'] as String,
          quantity: qty,
          unit: poolItem['unit'] as String,
          unitPrice: unitPrice,
          totalPrice: itemTotal,
          category: poolItem['cat'] as String,
        ),
      );
    }

    // Subtract 1-3 days for variety
    final date = DateTime.now().subtract(Duration(days: rand.nextInt(5), hours: rand.nextInt(12)));

    return Purchase(
      accessKey: accessKey.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString().padRight(44, '0') : accessKey,
      storeName: store,
      date: date,
      totalValue: double.parse(total.toStringAsFixed(2)),
      items: items,
    );
  }
}
