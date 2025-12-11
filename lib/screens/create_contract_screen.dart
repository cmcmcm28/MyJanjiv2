import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'contract_preview_screen.dart';
import '../theme/app_theme.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  String? _selectedCategory;
  String? _selectedTemplate;

  // Category to Types mapping
  static const Map<String, List<String>> _categoryTypes = {
    'MONEY_FINANCE': ['FRIENDLY_LOAN', 'BILL_SPLIT'],
    'ITEMS_ASSETS': ['ITEM_BORROW', 'VEHICLE_USE'],
    'SERVICES_GIG': ['FREELANCE_JOB', 'SALE_DEPOSIT'],
  };

  static const Map<String, String> _categoryNames = {
    'MONEY_FINANCE': 'Money & Finance',
    'ITEMS_ASSETS': 'Items & Assets',
    'SERVICES_GIG': 'Services & Gig Work',
  };

  static const Map<String, String> _typeNames = {
    'FRIENDLY_LOAN': 'Friendly Loan',
    'BILL_SPLIT': 'Bill Split / IOU',
    'ITEM_BORROW': 'Item Borrowing',
    'VEHICLE_USE': 'Vehicle Use',
    'FREELANCE_JOB': 'Freelance Job',
    'SALE_DEPOSIT': 'Sales Deposit',
  };

  // Controller for contract topic
  final _topicController = TextEditingController();

  // Controllers for different template types
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _shareController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalController = TextEditingController();
  final _itemController = TextEditingController();
  final _conditionController = TextEditingController();
  final _valueController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _fuelController = TextEditingController();
  final _taskController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();

  // Date variables for different template types
  DateTime? _contractStartDateFriendlyLoan; // FRIENDLY_LOAN
  DateTime? _contractDueDateFriendlyLoan; // FRIENDLY_LOAN (was repaymentDate)
  DateTime? _contractStartDateBillSplit; // BILL_SPLIT
  DateTime? _contractDueDateBillSplit; // BILL_SPLIT (was dueDate)
  DateTime? _contractStartDateItemBorrow; // ITEM_BORROW
  DateTime? _contractDueDateItemBorrow; // ITEM_BORROW (was returnDate)
  DateTime? _contractStartDateVehicleUse; // VEHICLE_USE (was startDate)
  DateTime? _contractDueDateVehicleUse; // VEHICLE_USE (was endDate)
  DateTime? _contractStartDateFreelanceJob; // FREELANCE_JOB
  DateTime? _contractDueDateFreelanceJob; // FREELANCE_JOB (was deadline)
  DateTime? _contractStartDateSaleDeposit; // SALE_DEPOSIT
  DateTime? _contractDueDateSaleDeposit; // SALE_DEPOSIT (was balanceDueDate)

  @override
  void dispose() {
    _topicController.dispose();
    _amountController.dispose();
    _purposeController.dispose();
    _shareController.dispose();
    _descriptionController.dispose();
    _totalController.dispose();
    _itemController.dispose();
    _conditionController.dispose();
    _valueController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _fuelController.dispose();
    _taskController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Map<String, dynamic> _getFormData() {
    // Base form data with topic
    Map<String, dynamic> baseData = {
      'topic': _topicController.text.trim(),
    };

    Map<String, dynamic> templateData;
    switch (_selectedTemplate) {
      case 'FRIENDLY_LOAN':
        templateData = {
          'amount': _amountController.text,
          'purpose': _purposeController.text,
          'contractStartDate': _contractStartDateFriendlyLoan != null
              ? _formatDate(_contractStartDateFriendlyLoan)
              : '',
          'contractDueDate': _contractDueDateFriendlyLoan != null
              ? _formatDate(_contractDueDateFriendlyLoan)
              : '',
        };
        break;
      case 'BILL_SPLIT':
        templateData = {
          'share': _shareController.text,
          'description': _descriptionController.text,
          'total': _totalController.text,
          'contractStartDate': _contractStartDateBillSplit != null
              ? _formatDate(_contractStartDateBillSplit)
              : '',
          'contractDueDate': _contractDueDateBillSplit != null
              ? _formatDate(_contractDueDateBillSplit)
              : '',
        };
        break;
      case 'ITEM_BORROW':
        templateData = {
          'item': _itemController.text,
          'condition': _conditionController.text,
          'contractStartDate': _contractStartDateItemBorrow != null
              ? _formatDate(_contractStartDateItemBorrow)
              : '',
          'contractDueDate': _contractDueDateItemBorrow != null
              ? _formatDate(_contractDueDateItemBorrow)
              : '',
          'value': _valueController.text,
        };
        break;
      case 'VEHICLE_USE':
        templateData = {
          'model': _modelController.text,
          'plate': _plateController.text,
          'contractStartDate': _contractStartDateVehicleUse != null
              ? _formatDate(_contractStartDateVehicleUse)
              : '',
          'contractDueDate': _contractDueDateVehicleUse != null
              ? _formatDate(_contractDueDateVehicleUse)
              : '',
          'fuel': _fuelController.text,
        };
        break;
      case 'FREELANCE_JOB':
        templateData = {
          'task': _taskController.text,
          'price': _priceController.text,
          'deposit': _depositController.text,
          'contractStartDate': _contractStartDateFreelanceJob != null
              ? _formatDate(_contractStartDateFreelanceJob)
              : '',
          'contractDueDate': _contractDueDateFreelanceJob != null
              ? _formatDate(_contractDueDateFreelanceJob)
              : '',
        };
        break;
      case 'SALE_DEPOSIT':
        templateData = {
          'item': _itemController.text,
          'price': _priceController.text,
          'deposit': _depositController.text,
          'contractStartDate': _contractStartDateSaleDeposit != null
              ? _formatDate(_contractStartDateSaleDeposit)
              : '',
          'contractDueDate': _contractDueDateSaleDeposit != null
              ? _formatDate(_contractDueDateSaleDeposit)
              : '',
        };
        break;
      default:
        templateData = {};
    }

    // Merge base data with template-specific data
    return {...baseData, ...templateData};
  }

  List<Widget> _buildTemplateFields() {
    if (_selectedCategory == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Please select a category',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    if (_selectedTemplate == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Please select a contract type',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    // Add topic field at the beginning
    List<Widget> fields = [
      // Section Header: Contract Details
      _buildSectionHeader('CONTRACT DETAILS'),
      const SizedBox(height: 16),
      _buildTextField(
        'Contract Topic',
        _topicController,
        Icons.label_outline,
        hintText: 'e.g., Photography Equipment, Home Improvement',
      ),
      const SizedBox(height: 20),
    ];

    // Add template-specific fields
    switch (_selectedTemplate) {
      case 'FRIENDLY_LOAN':
        fields.addAll([
          // Section Header: Financials
          _buildSectionHeader('FINANCIALS'),
          const SizedBox(height: 16),
          _buildAmountField('Amount', _amountController),
          const SizedBox(height: 20),
          _buildTextField('Purpose', _purposeController, Icons.description),
          const SizedBox(height: 20),
          // Section Header: Dates
          _buildSectionHeader('DATES'),
          const SizedBox(height: 16),
          _buildDatePicker(
              'Contract Start Date', _contractStartDateFriendlyLoan, (date) {
            setState(() => _contractStartDateFriendlyLoan = date);
          }),
          const SizedBox(height: 20),
          _buildDatePicker('Contract Due Date', _contractDueDateFriendlyLoan,
              (date) {
            setState(() => _contractDueDateFriendlyLoan = date);
          }),
        ]);
        break;
      case 'BILL_SPLIT':
        fields.addAll([
          // Section Header: Financials
          _buildSectionHeader('FINANCIALS'),
          const SizedBox(height: 16),
          _buildAmountField('Your Share', _shareController),
          const SizedBox(height: 20),
          _buildTextField(
              'Description', _descriptionController, Icons.description),
          const SizedBox(height: 20),
          _buildAmountField('Total Amount', _totalController),
          const SizedBox(height: 20),
          // Section Header: Dates
          _buildSectionHeader('DATES'),
          const SizedBox(height: 16),
          _buildDatePicker('Contract Start Date', _contractStartDateBillSplit,
              (date) {
            setState(() => _contractStartDateBillSplit = date);
          }),
          const SizedBox(height: 20),
          _buildDatePicker('Contract Due Date', _contractDueDateBillSplit,
              (date) {
            setState(() => _contractDueDateBillSplit = date);
          }),
        ]);
        break;
      case 'ITEM_BORROW':
        fields.addAll([
          // Section Header: Contract Details
          _buildSectionHeader('CONTRACT DETAILS'),
          const SizedBox(height: 16),
          _buildTextField('Item Name', _itemController, Icons.inventory),
          const SizedBox(height: 20),
          _buildTextField(
              'Condition', _conditionController, Icons.info_outline),
          const SizedBox(height: 20),
          // Section Header: Financials
          _buildSectionHeader('FINANCIALS'),
          const SizedBox(height: 16),
          _buildAmountField('Replacement Value', _valueController),
          const SizedBox(height: 20),
          // Section Header: Dates
          _buildSectionHeader('DATES'),
          const SizedBox(height: 16),
          _buildDatePicker('Contract Start Date', _contractStartDateItemBorrow,
              (date) {
            setState(() => _contractStartDateItemBorrow = date);
          }),
          const SizedBox(height: 20),
          _buildDatePicker('Contract Due Date', _contractDueDateItemBorrow,
              (date) {
            setState(() => _contractDueDateItemBorrow = date);
          }),
        ]);
        break;
      case 'VEHICLE_USE':
        fields.addAll([
          // Section Header: Contract Details
          _buildSectionHeader('CONTRACT DETAILS'),
          const SizedBox(height: 16),
          _buildTextField(
              'Vehicle Model', _modelController, Icons.directions_car),
          const SizedBox(height: 20),
          _buildTextField(
              'Plate Number', _plateController, Icons.confirmation_number),
          const SizedBox(height: 20),
          _buildTextField(
              'Fuel Agreement', _fuelController, Icons.local_gas_station),
          const SizedBox(height: 20),
          // Section Header: Dates
          _buildSectionHeader('DATES'),
          const SizedBox(height: 16),
          _buildDatePicker('Contract Start Date', _contractStartDateVehicleUse,
              (date) {
            setState(() => _contractStartDateVehicleUse = date);
          }),
          const SizedBox(height: 20),
          _buildDatePicker('Contract Due Date', _contractDueDateVehicleUse,
              (date) {
            setState(() => _contractDueDateVehicleUse = date);
          }),
        ]);
        break;
      case 'FREELANCE_JOB':
        fields.addAll([
          // Section Header: Contract Details
          _buildSectionHeader('CONTRACT DETAILS'),
          const SizedBox(height: 16),
          _buildTextField('Task Description', _taskController, Icons.work),
          const SizedBox(height: 20),
          // Section Header: Financials
          _buildSectionHeader('FINANCIALS'),
          const SizedBox(height: 16),
          _buildAmountField('Total Price', _priceController),
          const SizedBox(height: 20),
          _buildAmountField('Deposit', _depositController),
          const SizedBox(height: 20),
          // Section Header: Dates
          _buildSectionHeader('DATES'),
          const SizedBox(height: 16),
          _buildDatePicker(
              'Contract Start Date', _contractStartDateFreelanceJob, (date) {
            setState(() => _contractStartDateFreelanceJob = date);
          }),
          const SizedBox(height: 20),
          _buildDatePicker('Contract Due Date', _contractDueDateFreelanceJob,
              (date) {
            setState(() => _contractDueDateFreelanceJob = date);
          }),
        ]);
        break;
      case 'SALE_DEPOSIT':
        fields.addAll([
          // Section Header: Contract Details
          _buildSectionHeader('CONTRACT DETAILS'),
          const SizedBox(height: 16),
          _buildTextField('Item Name', _itemController, Icons.shopping_bag),
          const SizedBox(height: 20),
          // Section Header: Financials
          _buildSectionHeader('FINANCIALS'),
          const SizedBox(height: 16),
          _buildAmountField('Total Price', _priceController),
          const SizedBox(height: 20),
          _buildAmountField('Deposit', _depositController),
          const SizedBox(height: 20),
          // Section Header: Dates
          _buildSectionHeader('DATES'),
          const SizedBox(height: 16),
          _buildDatePicker('Contract Start Date', _contractStartDateSaleDeposit,
              (date) {
            setState(() => _contractStartDateSaleDeposit = date);
          }),
          const SizedBox(height: 20),
          _buildDatePicker('Contract Due Date', _contractDueDateSaleDeposit,
              (date) {
            setState(() => _contractDueDateSaleDeposit = date);
          }),
        ]);
        break;
    }

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient, // Light blue to light purple gradient
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Create New Contract',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Dropdown
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: _buildDropdownField(
                'Category',
                _selectedCategory,
                ['MONEY_FINANCE', 'ITEMS_ASSETS', 'SERVICES_GIG'],
                (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedTemplate =
                        null; // Reset template when category changes
                  });
                },
                displayNames: _categoryNames,
              ),
            ),
            const SizedBox(height: 20),
            // Type Dropdown (only shown when category is selected)
            if (_selectedCategory != null)
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 100),
                child: _buildDropdownField(
                  'Contract Type',
                  _selectedTemplate,
                  _categoryTypes[_selectedCategory] ?? [],
                  (value) => setState(() => _selectedTemplate = value),
                  displayNames: _typeNames,
                ),
              ),
            if (_selectedCategory != null) const SizedBox(height: 20),
            ..._buildTemplateFields().asMap().entries.map((entry) {
              final index = entry.key;
              final widget = entry.value;
              return FadeInDown(
                duration: Duration(milliseconds: 600 + (index * 100)),
                delay: Duration(milliseconds: 100 + (index * 50)),
                child: widget,
              );
            }),
            const SizedBox(height: 40),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
              child: ElevatedButton(
                onPressed: _selectedTemplate == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContractPreviewScreen(
                              templateType: _selectedTemplate!,
                              formData: _getFormData(),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue, // Solid blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0, // Flat design
                ),
                child: Text(
                  'Review Contract',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    Map<String, String>? displayNames,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          border: InputBorder.none,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              displayNames?[item] ?? item,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.headerBlue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAmountField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5), // Very light grey fill
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(
          fontSize: 24, // Large font size like banking app
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          prefixText: 'RM ',
          prefixStyle: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.headerBlue,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5), // Very light grey fill
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: GoogleFonts.poppins(),
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.poppins(),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () => _selectDate(context, onDateSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5), // Very light grey fill
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.grey[400],
                      fontWeight: selectedDate != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
