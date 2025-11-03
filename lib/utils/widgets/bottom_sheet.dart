// ────────────────────────────────────────────────────────────────────────────
// Bottom sheet content
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/styles.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';

class SurveyPickerSheet extends StatefulWidget {
  final QuestionnaireType? initialType;
  final String? initialCode;
  final void Function(QuestionnaireType type, String code, String? label) onApply;
  const SurveyPickerSheet({
    required this.onApply,
    this.initialType,
    this.initialCode,
  });

  @override
  State<SurveyPickerSheet> createState() => _SurveyPickerSheetState();
}

class _SurveyPickerSheetState extends State<SurveyPickerSheet> {
  QuestionnaireType? _type;
  String? _code;
  final ScrollController _scrollController = ScrollController();


  // Master lists based on your message
  static const rsiCodes = [
    'FR6','FR7','FR8','FR9','FR10','FR11','FR13','FR16','FR17','FR18',
    'PR/FR1','PR/FR2','PR/FR3','PR/FR5','PR/FR17','PR/FR19','PR/FR21','PR/FR22','PR/FR23',
  ];
  static const petrolCodes = [
    'PR6','PR7','PR8','PR9','PR10','PR11','PR12','PR13','PR14','PR16','PR18',
    'PR/FR1','PR/FR2','PR/FR3','PR/FR5',
  ];
  static const borderCodes = [
    'PR/FR17','PR/FR19','PR/FR21','PR/FR22','PR/FR23',
  ];
  static const busCodes = [
    'PB1','PB2','PB3','PB4','PB5','PB6','PB7','PB8','PB9','PB10','PB11','PB12','PB13',
  ];
  static const hotelCodes = [
    'PH1','PH2','PH3','PH4','PH5','PH6','PH7','PH8','PH9','PH10','PH11','PH12',
  ];

  // Airport as label list (code == label for simplicity)
  static const airportLabels = [
    'Dubai Airport',
    'Sharjah Airport',
    'Abu Dhabi Airport',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _code = widget.initialCode;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _codesFor(QuestionnaireType t) {
    switch (t) {
      case QuestionnaireType.freightRsi:      return rsiCodes;
      case QuestionnaireType.passengerPetrol: return petrolCodes;
      case QuestionnaireType.passengerBorder: return borderCodes;
      case QuestionnaireType.bus:             return busCodes;
      case QuestionnaireType.hotel:           return hotelCodes;
      case QuestionnaireType.airport:         return airportLabels; // treat as codes/labels
      case QuestionnaireType.statedPreference:return const []; // no fixed sites
    }
  }

  String _typeTitle(QuestionnaireType t) {
    switch (t) {
      case QuestionnaireType.freightRsi:      return 'Freight RSI';
      case QuestionnaireType.passengerPetrol: return 'Passenger – Petrol';
      case QuestionnaireType.passengerBorder: return 'Passenger – Border';
      case QuestionnaireType.bus:             return 'Bus Station';
      case QuestionnaireType.airport:         return 'Airport';
      case QuestionnaireType.hotel:           return 'Hotel';
      case QuestionnaireType.statedPreference:return 'Stated Preference';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTypes = QuestionnaireType.values.where((t) => t != QuestionnaireType.statedPreference).toList();

    final codes = _type == null ? const <String>[] : _codesFor(_type!);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Survey Type', style: AppFonts.text16.semiBold.style),
            ),
            const SizedBox(height: 8),

            // Types wrap
            Wrap(
              spacing: 8, runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.start,
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              children: allTypes.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(_typeTitle(t), style: AppFonts.text12.regular.style.copyWith(
                      color: selected ? AppColors.white : AppColors.textPrimary),),
                  selected: selected,
                  backgroundColor: AppColors.white,
                  selectedColor: AppColors.primary,
                  checkmarkColor: selected ? AppColors.white : AppColors.textPrimary,
                  onSelected: (_) {
                    setState(() {
                      _type = t;
                      _code = null; // reset when type changes
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Location Code', style: AppFonts.text16.semiBold.style),
            ),
            const SizedBox(height: 8),

            if (_type == null)
              Container(
                height: 60,
                alignment: Alignment.center,
                child: Text('Pick a survey type first', style: AppFonts.text14.regular.grey.style),
              )
            else if (codes.isEmpty)
              Container(
                height: 60,
                alignment: Alignment.center,
                child: Text('No fixed locations for this type', style: AppFonts.text14.regular.grey.style),
              )
            else
              SizedBox(
                height: 400,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true, // ensures scrollbar is always visible
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 4,
                    ),
                    itemCount: codes.length,
                    itemBuilder: (_, i) {
                      final code = codes[i];
                      final selected = _code == code;
                      return GestureDetector(
                        onTap: () => setState(() => _code = code),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? AppColors.primary : Colors.black12),
                          ),
                          child: Text(
                            code,
                            style: selected ? AppFonts.text14.medium.white.style : AppFonts.text14.medium.style,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Apply',
                    onPressed: () {
                      if (_type == null || _code == null) return;
                      // For airport we use label == code (e.g., "Dubai Airport")
                      final isAirport = _type == QuestionnaireType.airport;
                      final label = isAirport ? _code : null;
                      widget.onApply(_type!, _code!, label);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}