// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_driver/models/delivery.dart';
import 'package:flutter_driver/services/delivery_service.dart';
import 'package:intl/intl.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';

class MyDeliveries extends StatefulWidget {
  const MyDeliveries({super.key});

  @override
  State<MyDeliveries> createState() => _MyDeliveriesState();
}

class _MyDeliveriesState extends State<MyDeliveries> {
  bool _isLoading = true;
  DeliveryHistoryResponse? _historyResponse;
  List<Delivery> _filteredDeliveries = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await DeliveryService.getDeliveryHistory(
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
        companyId: _selectedCompanyId,
        groupBy: 'day',
      );

      if (result != null) {
        final response = DeliveryHistoryResponse.fromJson(result);
        final allDeliveries = response.allDeliveries;

        setState(() {
          _historyResponse = response;
          _filteredDeliveries = allDeliveries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar entregas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: theme,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadDeliveries();
    }
  }

  String _formatCurrency(String? value) {
    if (value == null || value.isEmpty) return 'R\$ 0,00';
    final number = double.tryParse(value) ?? 0.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(number);
  }

  String _formatDistance(String? value) {
    if (value == null || value.isEmpty) return '0 km';
    final number = double.tryParse(value) ?? 0.0;
    return '${number.toStringAsFixed(1)} km';
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '0 min';
    final minutes = int.tryParse(time) ?? 0;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
    return '$minutes min';
  }

  void _showDeliveryDetails(Delivery delivery) {
    var media = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: media.width * 0.8,
            padding: EdgeInsets.all(media.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with theme color
                Container(
                  padding: EdgeInsets.only(bottom: media.width * 0.03),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme, width: 2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(
                        text: 'Detalhes',
                        size: media.width * sixteen,
                        fontweight: FontWeight.bold,
                        color: textColor,
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, size: media.width * 0.05, color: textColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.03),
                // Info rows
                _buildCompactRow('Empresa', delivery.companyName ?? '-', media),
                _buildCompactRow('Cliente', delivery.customerName ?? '-', media),
                _buildCompactRow('Tempo', _formatTime(delivery.estimatedTime), media),
                _buildCompactRow('Distância', _formatDistance(delivery.distance), media),
                _buildCompactRow('Valor', _formatCurrency(delivery.driverAmount), media),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(String label, String value, Size media) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: media.width * 0.015),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            text: label,
            size: media.width * twelve,
            color: Colors.grey[600]!,
          ),
          MyText(
            text: value,
            size: media.width * twelve,
            fontweight: FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    var media = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: media.width * 0.05,
        vertical: media.width * 0.03,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            text: 'Filtros',
            size: media.width * fourteen,
            color: textColor,
          ),
          InkWell(
            onTap: _selectDateRange,
            child: Icon(
              Icons.tune,
              color: Colors.grey[600],
              size: media.width * 0.06,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_historyResponse == null) return const SizedBox.shrink();

    final stats = _historyResponse!.stats;
    var media = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: media.width * 0.05),
      padding: EdgeInsets.all(media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stats icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Total',
                '${stats.totalDeliveries}',
                Icons.inventory_2_outlined,
                const Color(0xFF9C27B0),
                media,
              ),
              _buildStatItem(
                'Concluídas',
                '${stats.completedDeliveries}',
                Icons.check_circle_outline,
                const Color(0xFF9C27B0),
                media,
              ),
              _buildStatItem(
                'Canceladas',
                '${stats.cancelledDeliveries}',
                Icons.cancel_outlined,
                const Color(0xFF9C27B0),
                media,
              ),
            ],
          ),
          SizedBox(height: media.width * 0.04),
          // Total and Distance row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Total',
                    size: media.width * twelve,
                    color: Colors.grey[500]!,
                  ),
                  MyText(
                    text: _formatCurrency(stats.totalEarnings.toString()),
                    size: media.width * sixteen,
                    fontweight: FontWeight.bold,
                    color: textColor,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MyText(
                    text: 'Distância total',
                    size: media.width * twelve,
                    color: Colors.grey[500]!,
                  ),
                  MyText(
                    text: _formatDistance(stats.totalDistance.toString()),
                    size: media.width * sixteen,
                    fontweight: FontWeight.bold,
                    color: textColor,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color, Size media) {
    return Column(
      children: [
        Container(
          width: media.width * 0.12,
          height: media.width * 0.12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: media.width * 0.06, color: color),
        ),
        SizedBox(height: media.width * 0.02),
        MyText(
          text: value,
          size: media.width * eighteen,
          fontweight: FontWeight.bold,
          color: textColor,
        ),
        MyText(
          text: label,
          size: media.width * ten,
          color: Colors.grey[500]!,
        ),
      ],
    );
  }

  Map<String, List<Delivery>> _groupDeliveriesByDate() {
    final Map<String, List<Delivery>> grouped = {};
    for (var delivery in _filteredDeliveries) {
      final date = _formatDate(delivery.deliveredAt);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(delivery);
    }
    return grouped;
  }

  Widget _buildDeliveryList() {
    var media = MediaQuery.of(context).size;

    if (_filteredDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: media.width * 0.2,
              color: Colors.grey[400],
            ),
            SizedBox(height: media.width * 0.05),
            MyText(
              text: 'Nenhuma entrega encontrada',
              size: media.width * sixteen,
              color: textColor.withOpacity(0.7),
            ),
          ],
        ),
      );
    }

    final groupedDeliveries = _groupDeliveriesByDate();
    final dates = groupedDeliveries.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.all(media.width * 0.05),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final deliveries = groupedDeliveries[date]!;
        return _buildDateGroup(date, deliveries, media);
      },
    );
  }

  Widget _buildDateGroup(String date, List<Delivery> deliveries, Size media) {
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: media.width * 0.04,
              vertical: media.width * 0.03,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: media.width * 0.04,
                  color: const Color(0xFF9C27B0),
                ),
                SizedBox(width: media.width * 0.02),
                MyText(
                  text: date,
                  size: media.width * fourteen,
                  fontweight: FontWeight.w600,
                  color: textColor,
                ),
                const Spacer(),
                MyText(
                  text: '${deliveries.length} ${deliveries.length == 1 ? 'entrega' : 'entregas'}',
                  size: media.width * twelve,
                  color: Colors.grey[600]!,
                ),
              ],
            ),
          ),
          // Deliveries list
          ...deliveries.map((delivery) => _buildDeliveryItem(delivery, media)),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(Delivery delivery, Size media) {
    return InkWell(
      onTap: () => _showDeliveryDetails(delivery),
      child: Container(
        padding: EdgeInsets.all(media.width * 0.03),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          children: [
            // Company name
            Expanded(
              flex: 2,
              child: MyText(
                text: delivery.companyName ?? 'Empresa',
                size: media.width * twelve,
                fontweight: FontWeight.w600,
                color: textColor,
              ),
            ),
            // Value
            Container(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.02, vertical: media.width * 0.01),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: MyText(
                text: _formatCurrency(delivery.driverAmount),
                size: media.width * ten,
                fontweight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(width: media.width * 0.02),
            // Distance
            Container(
              padding: EdgeInsets.symmetric(horizontal: media.width * 0.02, vertical: media.width * 0.01),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: MyText(
                text: _formatDistance(delivery.distance),
                size: media.width * ten,
                fontweight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        backgroundColor: page,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: MyText(
            text: 'Minhas Entregas',
            size: media.width * eighteen,
            fontweight: FontWeight.bold,
            color: textColor,
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme),
                ),
              )
            : Column(
                children: [
                  _buildFilterRow(),
                  _buildStatsCard(),
                  SizedBox(height: media.width * 0.03),
                  Expanded(child: _buildDeliveryList()),
                ],
              ),
      ),
    );
  }
}
