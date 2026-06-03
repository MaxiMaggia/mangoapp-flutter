import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../domain/dolar_quote.dart';
import '../utils/formatter.dart';
import '../viewmodels/providers.dart';

// Pantalla que lista las cotizaciones actuales del dolar (compra/venta por tipo).
class DolarRatesScreen extends ConsumerWidget {
  static const name = 'DolarRatesScreen';
  const DolarRatesScreen({super.key});

  // Arma la UI segun el estado async de las cotizaciones (cargando/error/datos).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(dolarQuotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cotizaciones del dólar')),
      body: quotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(dolarQuotesProvider),
        ),
        data: (quotes) => RefreshIndicator(
          // Pull-to-refresh: invalida y vuelve a pedir las cotizaciones.
          onRefresh: () async {
            ref.invalidate(dolarQuotesProvider);
            await ref.read(dolarQuotesProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: quotes.length,
            itemBuilder: (context, index) => _QuoteCard(quote: quotes[index]),
          ),
        ),
      ),
    );
  }
}

// Vista de error con boton para reintentar la carga de cotizaciones.
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar las cotizaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de una cotizacion: nombre, compra/venta y cuando se actualizo.
class _QuoteCard extends StatelessWidget {
  final DolarQuote quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.nombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mangoDeep,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PriceColumn(label: 'Compra', value: quote.compra),
                ),
                Expanded(
                  child: _PriceColumn(label: 'Venta', value: quote.venta),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Actualizado: ${Fmt.dateTime(quote.fechaActualizacion.toLocal())}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Columna chica con una etiqueta (Compra/Venta) y su valor formateado.
class _PriceColumn extends StatelessWidget {
  final String label;
  final double value;
  const _PriceColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          Fmt.money(value),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
