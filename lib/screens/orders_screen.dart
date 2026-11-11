import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../state/playapp_state.dart';
import '../theme/playapp_theme.dart';
import '../widgets/playapp_badges.dart';
import 'payment_gateway_screen.dart';

/// Historial y estado de pedidos del cliente (`user-orders.html`).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  EstadoPedido? _filtroEstado;

  @override
  Widget build(BuildContext context) {
    final state = PlayAppScope.of(context);
    final pedidos = state.pedidosDelCliente(estado: _filtroEstado);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtroEstado == null,
                  onSelected: (_) => setState(() => _filtroEstado = null),
                ),
                const SizedBox(width: 6),
                ...EstadoPedido.values.map((estado) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(estado.etiqueta),
                      selected: _filtroEstado == estado,
                      onSelected: (_) => setState(() => _filtroEstado = estado),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Expanded(
          child: pedidos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 56,
                          color: PlayAppColors.mutedText,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No hay pedidos registrados con este filtro.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => state.selectTab(1),
                          child: const Text('Ir a la Tienda'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
                  itemCount: pedidos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) =>
                      _OrderCard(pedido: pedidos[idx]),
                ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final puedeReintentarPago = pedido.pago.estado != EstadoPago.terminado;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Text(
              '#${pedido.id}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              formatCop(pedido.total),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: PlayAppColors.primaryBlue,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDateTime(pedido.timestamp)} · ${pedido.items.length} producto(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: PlayAppColors.mutedText,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  PlayAppPillBadge(
                    label: 'Pedido: ${pedido.estado.etiqueta}',
                    backgroundColor: pedido.estado.color,
                    textColor: pedido.estado.textColor,
                  ),
                  PlayAppPillBadge(
                    label: 'Pago: ${pedido.pago.estado.etiqueta}',
                    backgroundColor: pedido.pago.estado.color,
                    textColor: pedido.pago.estado.textColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          ...pedido.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${item.nombre} x ${item.cantidad}'),
                  ),
                  Text(formatCop(item.subtotal)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: PlayAppColors.mutedText),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${pedido.envio.direccion} (Carpa/Mesa ${pedido.envio.mesaCarpa})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: PlayAppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
          if (puedeReintentarPago) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PaymentGatewayScreen(pedido: pedido),
                    ),
                  );
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('Completar Pago'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
