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
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCompanyId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

        _applyFilters();
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

  void _applyFilters() {
    if (_historyResponse == null) return;

    var filtered = _historyResponse!.allDeliveries;

    // Filtrar por texto de busca (nome da empresa)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((delivery) {
        final companyName = delivery.companyName?.toLowerCase() ?? '';
        return companyName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredDeliveries = filtered;
    });
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

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadDeliveries();
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

  Widget _buildStatsCard() {
    if (_historyResponse == null) return const SizedBox.shrink();

    final stats = _historyResponse!.stats;
    var media = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.all(media.width * 0.05),
      padding: EdgeInsets.all(media.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'Resumo',
            size: media.width * eighteen,
            fontweight: FontWeight.bold,
            color: textColor,
          ),
          SizedBox(height: media.width * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Total',
                '${stats.totalDeliveries}',
                Icons.local_shipping,
                media,
              ),
              _buildStatItem(
                'Concluídas',
                '${stats.completedDeliveries}',
                Icons.check_circle,
                media,
              ),
              _buildStatItem(
                'Canceladas',
                '${stats.cancelledDeliveries}',
                Icons.cancel,
                media,
              ),
            ],
          ),
          SizedBox(height: media.width * 0.03),
          Divider(color: Colors.grey[300]),
          SizedBox(height: media.width * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'Ganhos Totais',
                    size: media.width * twelve,
                    color: textColor.withOpacity(0.7),
                  ),
                  MyText(
                    text: _formatCurrency(stats.totalEarnings.toString()),
                    size: media.width * sixteen,
                    fontweight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MyText(
                    text: 'Distância Total',
                    size: media.width * twelve,
                    color: textColor.withOpacity(0.7),
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

  Widget _buildStatItem(String label, String value, IconData icon, Size media) {
    return Column(
      children: [
        Icon(icon, size: media.width * 0.08, color: theme),
        SizedBox(height: media.width * 0.01),
        MyText(
          text: value,
          size: media.width * eighteen,
          fontweight: FontWeight.bold,
          color: textColor,
        ),
        MyText(
          text: label,
          size: media.width * twelve,
          color: textColor.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    var media = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(media.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Campo de busca
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por empresa...',
              prefixIcon: Icon(Icons.search, color: theme),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: media.width * 0.04,
                vertical: media.width * 0.03,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          SizedBox(height: media.width * 0.03),
          // Filtro de data
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: EdgeInsets.all(media.width * 0.03),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: theme, size: media.width * 0.05),
                        SizedBox(width: media.width * 0.02),
                        Expanded(
                          child: MyText(
                            text: _startDate != null && _endDate != null
                                ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                : 'Selecionar período',
                            size: media.width * fourteen,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateFilter,
                  color: theme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryGrid() {
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

    return ListView.builder(
      padding: EdgeInsets.all(media.width * 0.05),
      itemCount: _filteredDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = _filteredDeliveries[index];
        return _buildDeliveryCard(delivery, media);
      },
    );
  }

  Widget _buildDeliveryCard(Delivery delivery, Size media) {
    return Container(
      margin: EdgeInsets.only(bottom: media.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com data e status
          Container(
            padding: EdgeInsets.all(media.width * 0.03),
            decoration: BoxDecoration(
              color: theme.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: media.width * 0.04, color: theme),
                    SizedBox(width: media.width * 0.02),
                    MyText(
                      text: _formatDate(delivery.deliveredAt),
                      size: media.width * fourteen,
                      fontweight: FontWeight.w600,
                      color: textColor,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: media.width * 0.03,
                    vertical: media.width * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: delivery.status == 'completed'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MyText(
                    text: delivery.status == 'completed' ? 'Concluída' : 'Cancelada',
                    size: media.width * twelve,
                    fontweight: FontWeight.w600,
                    color: delivery.status == 'completed' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo
          Padding(
            padding: EdgeInsets.all(media.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Empresa
                if (delivery.companyName != null)
                  Row(
                    children: [
                      Icon(Icons.business, size: media.width * 0.05, color: theme),
                      SizedBox(width: media.width * 0.02),
                      Expanded(
                        child: MyText(
                          text: delivery.companyName!,
                          size: media.width * sixteen,
                          fontweight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: media.width * 0.03),
                // Grid de informações
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Valor',
                        _formatCurrency(delivery.driverAmount),
                        Icons.attach_money,
                        Colors.green,
                        media,
                      ),
                    ),
                    SizedBox(width: media.width * 0.02),
                    Expanded(
                      child: _buildInfoItem(
                        'Distância',
                        _formatDistance(delivery.distance),
                        Icons.route,
                        Colors.blue,
                        media,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Size media,
  ) {
    return Container(
      padding: EdgeInsets.all(media.width * 0.03),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: media.width * 0.04, color: color),
              SizedBox(width: media.width * 0.01),
              MyText(
                text: label,
                size: media.width * twelve,
                color: textColor.withOpacity(0.7),
              ),
            ],
          ),
          SizedBox(height: media.width * 0.01),
          MyText(
            text: value,
            size: media.width * fourteen,
            fontweight: FontWeight.bold,
            color: textColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        backgroundColor: page,
        body: Column(
          children: [
            // AppBar customizado
            Container(
                padding: EdgeInsets.only(
                  left: media.width * 0.05,
                  right: media.width * 0.05,
                  top: MediaQuery.of(context).padding.top + media.width * 0.05,
                  bottom: media.width * 0.05,
                ),
                decoration: BoxDecoration(
                  color: theme,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: media.width * 0.1,
                        width: media.width * 0.1,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: media.width * 0.05,
                        ),
                      ),
                    ),
                    SizedBox(width: media.width * 0.03),
                    MyText(
                      text: 'Minhas Entregas',
                      size: media.width * twenty,
                      fontweight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Conteúdo
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(theme),
                        ),
                      )
                    : Column(
                        children: [
                          _buildStatsCard(),
                          _buildFilters(),
                          Expanded(child: _buildDeliveryGrid()),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
