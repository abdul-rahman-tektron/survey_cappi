import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/widgets/custom_round_checkbox.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';
import 'package:srpf/utils/widgets/custom_search_dropdown.dart';

class QMoneyPair extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QMoneyPair(this.q, this.n, this.sid, {super.key});

  @override
  State<QMoneyPair> createState() => _QMoneyPairState();
}

class _QMoneyPairState extends State<QMoneyPair> {
  late final TextEditingController _amountCtrl;

  Map<String, dynamic> get _cfg => widget.q.captureConfig ?? const {};
  Map<String, dynamic> get _specialCfg =>
      (_cfg['specialToggle'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v)) ??
          const {};
  Map<String, dynamic> get _amountCfg =>
      (_cfg['amount'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ??
          const {};
  Map<String, dynamic> get _currCfg =>
      (_cfg['currency'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ??
          const {};

  late final List<Map<String, dynamic>> _currOpts;

  String get _specialKey => (_specialCfg['key'] as String?) ?? 'special';
  String get _amountKey => (_amountCfg['key'] as String?) ?? 'amount';
  String get _currKey => (_currCfg['key'] as String?) ?? 'currency';
  String get _currLang => (_currCfg['lang'] as String?) ?? 'en';

  @override
  void initState() {
    super.initState();

    // Strong typing for currency options
    _currOpts = ((_currCfg['options'] as List?) ?? const [])
        .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final value = _currentValueMap();
    final amountText = value[_amountKey]?.toString() ?? '';

    _amountCtrl = TextEditingController(text: amountText);
  }

  @override
  void didUpdateWidget(covariant QMoneyPair oldWidget) {
    super.didUpdateWidget(oldWidget);

    // reflect answer changes for amount controller
    final value = _currentValueMap();
    final amountText = value[_amountKey]?.toString() ?? '';
    if (_amountCtrl.text != amountText) {
      _amountCtrl.text = amountText;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _currentValueMap() {
    final raw = widget.q.answer;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  void _savePatch(Map<String, dynamic> patch) {
    final next = _currentValueMap()..addAll(patch);
    widget.n.updateAnswer(widget.sid, widget.q.id, next);
  }

  @override
  Widget build(BuildContext context) {
    if (_cfg['moneyPair'] != true) return const SizedBox.shrink();

    final value = _currentValueMap();
    final bool special = (value[_specialKey] as bool?) ?? false;

    // resolve currently selected currency option from stored id
    final String? currencyId = value[_currKey]?.toString();
    final Map<String, dynamic>? initialCurrency = currencyId == null
        ? null
        : _currOpts.firstWhere(
          (o) => (o['id'] as String?) == currencyId,
      orElse: () => <String, dynamic>{},
    ).isEmpty
        ? null
        : _currOpts.firstWhere(
          (o) => (o['id'] as String?) == currencyId,
    );

    final bool currencyRequired = (_currCfg['required'] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
// inside build(), replace the whole CheckboxListTile(...) with this:
        if (_specialCfg.isNotEmpty)
    Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          final newVal = !special;
          if (newVal) {
            _savePatch({_specialKey: true, _amountKey: null, _currKey: null});
            _amountCtrl.text = '';
          } else {
            _savePatch({_specialKey: false});
          }
          setState(() {});
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomRoundCheckbox(
              value: special,
              onChanged: (v) {
                if (v) {
                  _savePatch({_specialKey: true, _amountKey: null, _currKey: null});
                  _amountCtrl.text = '';
                } else {
                  _savePatch({_specialKey: false});
                }
                setState(() {});
              },
              activeColor: AppColors.primary,
              checkColor: AppColors.white,
              borderColor: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (_specialCfg['label'] as String?) ?? 'Unknown / Refused',
                style: AppFonts.text14.regular.style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),

        Row(
          children: [
            // Amount field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CustomTextField(
                  controller: _amountCtrl,
                  fieldName: (_amountCfg['label'] as String?) ?? 'Amount',
                  hintText: 'Enter amount',
                  keyboardType: TextInputType.number,
                  isEditable: !special,
                  isEnable: !special,
                  skipValidation: special, // not required when special is ON
                  onChanged: (txt) {
                    final num? parsed =
                    _tryParse(txt, decimal: (_amountCfg['decimal'] == true));
                    _savePatch({_amountKey: parsed});
                  },
                ),
              ),
            ),

            // Currency dropdown (uses your dropdown_search-based wrapper)
            Expanded(
              child: Opacity(
                opacity: special ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: special,
                  child: CustomSearchDropdown<Map<String, dynamic>>(
                    items: _currOpts,
                    initialValue: initialCurrency,
                    fieldName: (_currCfg['label'] as String?) ?? 'Currency',
                    hintText: 'Select currency',
                    currentLang: _currLang,
                    isEnable: !special,
                    skipValidation: special, // not required when special is ON
                    // label / display
                    itemLabel: (item, lang) =>
                    (item['label'] as String?) ??
                        (item['id'] as String? ?? ''),
                    // validator takes String?
                    validator: (String? val) {
                      if (!special &&
                          currencyRequired &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Please select a currency';
                      }
                      return null;
                    },
                    // store id back
                    onSelected: (item) {
                      final String? id =
                      item == null ? null : (item['id'] as String?);
                      _savePatch({_currKey: id});
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _labelForId(
      List<Map<String, dynamic>> options, String? id) {
    if (id == null) return null;
    for (final o in options) {
      if ((o['id'] as String?) == id) {
        return (o['label'] as String?) ?? id;
      }
    }
    return id; // fallback keeps UI meaningful
  }

  num? _tryParse(String s, {bool decimal = true}) {
    final t = s.trim();
    if (t.isEmpty) return null;
    try {
      return decimal ? num.parse(t) : int.parse(t);
    } catch (_) {
      return null;
    }
  }
}