// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../models/support_ticket.dart';
import '../../services/support_ticket_service.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/nointernet.dart';
import 'create_support_ticket.dart';
import 'ticket_details.dart';

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  bool _isLoading = true;
  List<SupportTicket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🎫 Carregando tickets do motorista...');

      final tickets = await SupportTicketService.getMyTickets();

      setState(() {
        _tickets = tickets;
      });

      debugPrint('✅ ${tickets.length} tickets carregados');
    } catch (e) {
      debugPrint('❌ Erro ao carregar tickets: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateSupportTicketPage(),
      ),
    );

    if (result == true) {
      _loadTickets();
    }
  }

  Future<void> _navigateToTicketDetails(SupportTicket ticket) async {
    debugPrint('🔍 Navigating to ticket details with ID: "${ticket.id}"');
    debugPrint('🔍 Ticket subject: ${ticket.subjectName}');
    debugPrint('🔍 Ticket message: ${ticket.message}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsPage(ticketId: ticket.id),
      ),
    );

    if (result == true) {
      _loadTickets();
    }
  }

  // Cor primária roxa do design
  static const Color _primaryPurple = Color(0xFF7C3AED);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF10B981); // Verde
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'resolved':
        return Icons.done_all;
      case 'closed':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return SafeArea(
      child: Material(
        child: ValueListenableBuilder(
          valueListenable: valueNotifierHome.value,
          builder: (context, value, child) {
            return Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Stack(
                children: [
                  Container(
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
                    padding: EdgeInsets.fromLTRB(
                        media.width * 0.05, media.width * 0.05, media.width * 0.05, 0),
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top),
                        Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.only(bottom: media.width * 0.05),
                              width: media.width * 1,
                              alignment: Alignment.center,
                              child: MyText(
                                text: 'Tickets',
                                size: media.width * twenty,
                                fontweight: FontWeight.w600,
                              ),
                            ),
                            Positioned(
                              child: InkWell(
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                child: Icon(Icons.menu, color: textColor),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: media.width * 0.05),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadTickets,
                            child: _tickets.isEmpty && !_isLoading
                                ? SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: Container(
                                      height: media.height * 0.6,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.support_agent,
                                            size: media.width * 0.2,
                                            color: textColor.withValues(alpha: 0.3),
                                          ),
                                          SizedBox(height: media.width * 0.05),
                                          Text(
                                            'Nenhum ticket encontrado',
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * sixteen,
                                              color: textColor.withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: media.width * 0.02),
                                          Text(
                                            'Crie um ticket para falar com o suporte',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.notoSans(
                                              fontSize: media.width * fourteen,
                                              color: textColor.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: _tickets.length,
                                    padding: EdgeInsets.only(bottom: media.width * 0.2),
                                    itemBuilder: (context, index) {
                                      final ticket = _tickets[index];
                                      final statusColor = _getStatusColor(ticket.status);
                                      final statusIcon = _getStatusIcon(ticket.status);

                                      return Container(
                                        margin: EdgeInsets.only(bottom: media.width * 0.04),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap: () => _navigateToTicketDetails(ticket),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: EdgeInsets.all(media.width * 0.04),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Header com assunto e status
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            ticket.subjectName,
                                                            style: GoogleFonts.notoSans(
                                                              fontSize: media.width * sixteen,
                                                              fontWeight: FontWeight.bold,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                          SizedBox(height: media.width * 0.01),
                                                          Text(
                                                            'Ticket #${ticket.ticketNumber.isNotEmpty ? ticket.ticketNumber : ticket.id}',
                                                            style: GoogleFonts.notoSans(
                                                              fontSize: media.width * twelve,
                                                              color: textColor.withValues(alpha: 0.5),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          statusIcon,
                                                          size: media.width * 0.045,
                                                          color: statusColor,
                                                        ),
                                                        SizedBox(width: media.width * 0.01),
                                                        Text(
                                                          ticket.getStatusText(),
                                                          style: GoogleFonts.notoSans(
                                                            fontSize: media.width * fourteen,
                                                            color: statusColor,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: media.width * 0.03),
                                                // Imagem anexada (se houver)
                                                if (ticket.images.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.attach_file,
                                                        size: media.width * 0.04,
                                                        color: _primaryPurple,
                                                      ),
                                                      SizedBox(width: media.width * 0.01),
                                                      Text(
                                                        'Imagem anexada',
                                                        style: GoogleFonts.notoSans(
                                                          fontSize: media.width * fourteen,
                                                          color: _primaryPurple,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                SizedBox(height: media.width * 0.02),
                                                // Tempo
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: media.width * 0.04,
                                                      color: textColor.withValues(alpha: 0.4),
                                                    ),
                                                    SizedBox(width: media.width * 0.015),
                                                    Text(
                                                      _formatDate(ticket.createdAt),
                                                      style: GoogleFonts.notoSans(
                                                        fontSize: media.width * twelve,
                                                        color: textColor.withValues(alpha: 0.4),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botão flutuante para criar novo ticket
                  Positioned(
                    bottom: media.width * 0.08,
                    left: media.width * 0.1,
                    right: media.width * 0.1,
                    child: ElevatedButton(
                      onPressed: _navigateToCreateTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: media.width * 0.045,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: Colors.white),
                          SizedBox(width: media.width * 0.02),
                          Text(
                            'Novo Ticket',
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontSize: media.width * sixteen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // No internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(
                            onTap: () {
                              setState(() {
                                internetTrue();
                                _loadTickets();
                              });
                            },
                          ),
                        )
                      : Container(),

                  // Loader
                  (_isLoading == true)
                      ? const Positioned(top: 0, child: Loading())
                      : Container(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Agora';
        }
        return '${difference.inMinutes}min atrás';
      }
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
