import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../core/services/data_sync_controller.dart';
import '../../../data/services/payment_document_service.dart';
import '../../../shared/widgets/avatar_placeholder.dart';
import '../widgets/add_payment_dialog.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  int _filterIndex = 0;
  int _currentPage = 1;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  late Future<PaymentsPage> _paymentsFuture;
  late Future<PaymentSummary> _summaryFuture;

  static const _statusFilters = [null, 'overdue', 'pending', 'paid'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _load();
    dataSync.addListener(_onDataSync);
  }

  void _onDataSync() {
    if (mounted) {
      setState(() => _load());
    }
  }

  @override
  void dispose() {
    dataSync.removeListener(_onDataSync);
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    _paymentsFuture = PaymentRepository.getPayments(
      status: _statusFilters[_filterIndex],
      page: _currentPage,
    );
    _summaryFuture = PaymentRepository.getSummary();
  }

  void _onSearch(String val) => setState(() {
    _searchQuery = val;
  });

  void _setFilter(int idx) => setState(() {
    _filterIndex = idx;
    _currentPage = 1;
    _load();
  });

  void _setPage(int p) => setState(() {
    _currentPage = p;
    _load();
  });

  Future<void> _markPaid(ApiPayment p) async {
    try {
      await PaymentRepository.markPaid(p.id);
      dataSync.notify(DataRefreshEvent.payments);
      dataSync.notify(DataRefreshEvent.members);
      setState(() => _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _unmarkPaid(ApiPayment p) async {
    try {
      await PaymentRepository.unmarkPaid(p.id);
      dataSync.notify(DataRefreshEvent.payments);
      dataSync.notify(DataRefreshEvent.members);
      setState(() => _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    }
  }

  void _showAddPayment() async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(),
    );
    if (result == true) {
      dataSync.notify(DataRefreshEvent.payments);
      dataSync.notify(DataRefreshEvent.members);
      setState(() => _load());
    }
  }

  Future<void> _downloadInvoice(ApiPayment payment) async {
    try {
      final file = await PaymentDocumentService.saveInvoicePdf(payment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice saved to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF error: $e'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  Future<void> _openWhatsApp(ApiPayment payment) async {
    try {
      final file = await PaymentDocumentService.saveInvoicePdf(payment);
      await PaymentDocumentService.openWhatsAppForPayment(
        payment,
        attachmentPath: file.path,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp error: $e'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FadeTransition(
      opacity: _fade,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDesktop) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Expanded(child: _buildHeader(isDesktop))],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isDesktop)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _showAddPayment,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ADD PAYMENT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddPayment,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ADD PAYMENT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  _buildBentoStats(isDesktop),
                  const SizedBox(height: 32),
                  _buildFilterBar(isDesktop),
                  const SizedBox(height: 8),
                  _buildPaymentList(isDesktop),
                  const SizedBox(height: 40),
                  _buildSummaryFooter(isDesktop),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return FutureBuilder<PaymentSummary>(
      future: _summaryFuture,
      builder: (context, snap) {
        final summary = snap.data;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REVENUE CONTROL',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: AppColors.primary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PAYMENTS',
                  style: GoogleFonts.roboto(
                    fontSize: isDesktop ? 72 : 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
            if (isDesktop) const Spacer(),
            if (isDesktop && summary != null) ...[
              _HeaderStat(
                label: 'PENDING',
                value: 'Rs.${summary.pendingRevenue.toStringAsFixed(0)}',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 16),
              _HeaderStat(
                label: 'RECEIVED',
                value: 'Rs.${summary.totalRevenue.toStringAsFixed(0)}',
                color: AppColors.primary,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBentoStats(bool isDesktop) {
    return FutureBuilder<PaymentSummary>(
      future: _summaryFuture,
      builder: (context, snap) {
        final summary = snap.data;
        final recoveryRate =
            summary != null &&
                (summary.totalRevenue + summary.pendingRevenue) > 0
            ? summary.totalRevenue /
                  (summary.totalRevenue + summary.pendingRevenue)
            : 0.0;

        if (isDesktop) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _RecoveryCard(
                  rate: recoveryRate,
                  loading: !snap.hasData,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _OverdueCard(count: summary?.overdueCount ?? 0)),
            ],
          );
        }
        return Column(
          children: [
            _RecoveryCard(rate: recoveryRate, loading: !snap.hasData),
            const SizedBox(height: 16),
            _OverdueCard(count: summary?.overdueCount ?? 0),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(bool isDesktop) {
    final filters = ['ALL', 'OVERDUE', 'UPCOMING', 'COMPLETED'];
    return Container(
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...filters.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: 24),
                child: GestureDetector(
                  onTap: () => _setFilter(e.key),
                  child: Text(
                    e.value,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: _filterIndex == e.key
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (isDesktop) const SizedBox(width: 40),
            if (isDesktop)
              Container(
                width: 200,
                height: 36,
                margin: const EdgeInsets.only(right: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'SEARCH MEMBER...',
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(bool isDesktop) {
    return FutureBuilder<PaymentsPage>(
      future: _paymentsFuture,
      builder: (context, snap) {
        final allPayments = snap.data?.payments ?? [];
        final payments = allPayments
            .where(
              (p) => p.memberName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();
        final loading = snap.connectionState == ConnectionState.waiting;

        return Container(
          color: AppColors.surfaceContainerLow,
          child: Column(
            children: [
              if (isDesktop)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  color: AppColors.surfaceContainerHighest.withOpacity(0.3),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: _ColHeader('MEMBER / INVOICE')),
                      Expanded(flex: 2, child: _ColHeader('AMOUNT')),
                      Expanded(flex: 2, child: _ColHeader('DUE DATE')),
                      Expanded(flex: 2, child: _ColHeader('STATUS')),
                      Expanded(
                        flex: 2,
                        child: _ColHeader('ACTION', align: TextAlign.right),
                      ),
                    ],
                  ),
                ),

              if (loading && payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Text(
                      'No payments found',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...payments.map(
                  (p) => _PaymentRow(
                    payment: p,
                    isDesktop: isDesktop,
                    onMarkReceived: () => _markPaid(p),
                    onUnmarkPaid: () => _unmarkPaid(p),
                    onDownloadPdf: () => _downloadInvoice(p),
                    onOpenWhatsApp: () => _openWhatsApp(p),
                  ),
                ),

              if (snap.data != null && snap.data!.pages > 1)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PAGE ${snap.data!.page} OF ${snap.data!.pages}',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () => _setPage(_currentPage - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: _currentPage < snap.data!.pages
                                ? () => _setPage(_currentPage + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryFooter(bool isDesktop) {
    return FutureBuilder<PaymentSummary>(
      future: _summaryFuture,
      builder: (context, snap) {
        final summary = snap.data;
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withOpacity(0.4),
            border: Border.all(
              color: AppColors.outlineVariant.withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    _FooterStat(
                      label: 'TOTAL RECEIVED',
                      value: summary != null
                          ? 'Rs.${summary.totalRevenue.toStringAsFixed(0)}'
                          : '—',
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: AppColors.outlineVariant.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    _FooterStat(
                      label: 'OVERDUE COUNT',
                      value: summary != null ? '${summary.overdueCount}' : '—',
                      valueColor: AppColors.secondary,
                    ),
                    const Spacer(),
                    _FooterBtn(label: 'DOWNLOAD REPORT', isPrimary: false),
                    const SizedBox(width: 16),
                    _FooterBtn(label: 'SEND REMINDERS', isPrimary: true),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _FooterStat(
                          label: 'TOTAL RECEIVED',
                          value: summary != null
                              ? 'Rs.${summary.totalRevenue.toStringAsFixed(0)}'
                              : '—',
                        ),
                        const SizedBox(width: 32),
                        _FooterStat(
                          label: 'OVERDUE',
                          value: summary != null
                              ? '${summary.overdueCount}'
                              : '—',
                          valueColor: AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _FooterBtn(
                            label: 'DOWNLOAD',
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FooterBtn(
                            label: 'SEND REMINDERS',
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final ApiPayment payment;
  final bool isDesktop;
  final VoidCallback onMarkReceived;
  final VoidCallback onUnmarkPaid;
  final VoidCallback onDownloadPdf;
  final VoidCallback onOpenWhatsApp;
  const _PaymentRow({
    required this.payment,
    required this.isDesktop,
    required this.onMarkReceived,
    required this.onUnmarkPaid,
    required this.onDownloadPdf,
    required this.onOpenWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = payment.status == PaymentStatus.overdue;
    final isPaid = payment.status == PaymentStatus.paid;

    if (!isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0D484847))),
        ),
        child: Row(
          children: [
            AvatarPlaceholder(
              initials: payment.initials,
              size: 40,
              paymentStatus: payment.status,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.memberName.toUpperCase(),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '${payment.plan} • ${payment.invoiceNumber}',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rs.${payment.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (payment.balanceAmount > 0 &&
                          payment.balanceAmount != payment.amount)
                        Text(
                          'BAL Rs.${payment.balanceAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (payment.balanceAmount > 0 &&
                          payment.balanceAmount != payment.amount)
                        const SizedBox(width: 8),
                      Text(
                        payment.dueDate,
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPaid)
                        _MobileActionBtn(
                          icon: Icons.check_circle_outline,
                          color: AppColors.primaryContainer,
                          tooltip: 'MARK RECEIVED',
                          onTap: onMarkReceived,
                        ),
                      _MobileActionBtn(
                        icon: Icons.download_rounded,
                        color: AppColors.onSurfaceVariant,
                        tooltip: 'DOWNLOAD PDF',
                        onTap: onDownloadPdf,
                      ),
                      _MobileActionBtn(
                        icon: Icons.chat_outlined,
                        color: AppColors.primaryContainer,
                        tooltip: 'WHATSAPP',
                        onTap: onOpenWhatsApp,
                      ),
                    ],
                  ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D484847))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          hoverColor: AppColors.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      AvatarPlaceholder(
                        initials: payment.initials,
                        size: 40,
                        paymentStatus: payment.status,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.memberName.toUpperCase(),
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              payment.invoiceNumber,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              payment.plan,
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant.withOpacity(
                                  0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    payment.balanceAmount > 0 &&
                            payment.balanceAmount != payment.amount
                        ? 'Rs.${payment.amount.toStringAsFixed(2)} / Bal Rs.${payment.balanceAmount.toStringAsFixed(2)}'
                        : 'Rs.${payment.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    payment.dueDate,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(flex: 2, child: _StatusBadge(status: payment.status)),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: isPaid
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: onDownloadPdf,
                                icon: const Icon(Icons.download_rounded, size: 18),
                                tooltip: 'DOWNLOAD PDF',
                                color: AppColors.onSurfaceVariant,
                              ),
                              IconButton(
                                onPressed: onOpenWhatsApp,
                                icon: const Icon(Icons.chat_outlined, size: 18),
                                tooltip: 'OPEN WHATSAPP',
                                color: AppColors.primaryContainer,
                              ),
                              IconButton(
                                onPressed: () =>
                                    _showRevertConfirm(context, onUnmarkPaid),
                                icon: const Icon(Icons.history, size: 20),
                                tooltip: 'REVERT TO UNRECEIVED',
                                color: AppColors.primaryContainer,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: onMarkReceived,
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                ),
                                tooltip: 'MARK RECEIVED',
                                color: AppColors.primaryContainer,
                              ),
                              IconButton(
                                onPressed: onDownloadPdf,
                                icon: const Icon(Icons.download_rounded, size: 18),
                                tooltip: 'DOWNLOAD PDF',
                                color: AppColors.onSurfaceVariant,
                              ),
                              IconButton(
                                onPressed: onOpenWhatsApp,
                                icon: const Icon(Icons.chat_outlined, size: 18),
                                tooltip: 'OPEN WHATSAPP',
                                color: AppColors.primaryContainer,
                              ),
                            ],
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

  void _showRevertConfirm(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'REVERT PAYMENT',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w900,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to mark this payment as unpaid?',
          style: GoogleFonts.roboto(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'REVERT',
              style: GoogleFonts.roboto(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _MobileActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PaymentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, textColor;
    String label;
    switch (status) {
      case PaymentStatus.overdue:
        bg = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        label = 'OVERDUE';
        break;
      case PaymentStatus.pending:
        bg = AppColors.surfaceContainerHighest;
        textColor = AppColors.onSurfaceVariant;
        label = 'PENDING';
        break;
      case PaymentStatus.paid:
        bg = AppColors.primaryContainer.withOpacity(0.15);
        textColor = AppColors.primaryContainer;
        label = 'PAID';
        break;
      case PaymentStatus.partial:
        bg = AppColors.primary.withOpacity(0.12);
        textColor = AppColors.primary;
        label = 'PARTIAL';
        break;
      case PaymentStatus.cancelled:
        bg = AppColors.error.withOpacity(0.12);
        textColor = AppColors.error;
        label = 'CANCELLED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: bg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final double rate;
  final bool loading;
  const _RecoveryCard({required this.rate, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECOVERY RATE',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loading
                ? 'Calculating...'
                : '${(rate * 100).toStringAsFixed(0)}% of members have completed their monthly fees.',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: rate.clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final int count;
  const _OverdueCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.warning_outlined,
                color: AppColors.onSecondaryContainer,
                size: 28,
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppColors.onSecondaryContainer,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            count.toString().padLeft(2, '0'),
            style: GoogleFonts.roboto(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.onSecondaryContainer,
              letterSpacing: -1,
            ),
          ),
          Text(
            'OVERDUE PAYMENTS',
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: AppColors.onSecondaryContainer.withOpacity(0.8),
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 8,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _ColHeader(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: GoogleFonts.roboto(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      color: AppColors.onSurfaceVariant,
      letterSpacing: 2.5,
    ),
  );
}

class _FooterStat extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _FooterStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 8,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: valueColor ?? AppColors.onSurface,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  const _FooterBtn({required this.label, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.secondary : Colors.transparent,
          border: isPrimary
              ? null
              : Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 30,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isPrimary ? AppColors.onSecondary : AppColors.onSurface,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
