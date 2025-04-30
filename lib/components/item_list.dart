import 'package:flutter/material.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/screens/item_form_screen.dart';

class ItemList extends StatelessWidget {
  final BuyItem item;

  const ItemList({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.isBuy ? Colors.blue : null,
      child: ListTile(
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Prix: ${item.price}'),
                const SizedBox(width: 10),
                Text('Qte: ${item.quantity}'),
                SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 5),
            Text('Date: ${item.date.toLocal().toString().split(' ')[0]}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Navigate to the item form screen with the item details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemFormScreen(item: item),
              ),
            );
          },
        ),

        onLongPress: () {},
      ),
    );
  }
}
