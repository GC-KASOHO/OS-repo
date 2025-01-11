from typing import List
import random

class Order:
    def __init__(self):
        self.orders: List[list] = []
    
    def add_order(self, name: str, quantity: int, price: float):
        order = {
            'name': name,
            'quantity': quantity,
            'price': price,
            'total': quantity * price,
            'status': 'Pending'
        }
        self.orders.append(order)
        print(f"Added: {name}")
    
    def display_orders(self):
        if not self.orders:
            print("No orders found")
            return
        
        print("\n=== Orders ===")
        for index, order in enumerate(self.orders, 1):
            print(
                f"{index}. {order['name']:<20} "
                f"Qty: {order['quantity']:<3} "
                f"Price: Php{order['price']:<6.2f} "
                f"Total: Php{order['total']:<7.2f} "
                f"Status: {order['status']}"
            )
    
    def display_grand_total(self):
        total_amount = sum(order['total'] for order in self.orders)
        print(f"\nGrand Total: Php{total_amount:.2f}")
        return total_amount
    
    def process_orders(self):
        print("""
                Are you sure you want to process all orders?
                ('y' or 'n')
                """
                )
        
        prompt = input("Enter your choice:")
        pending_orders = [
            order for order in self.orders if order['status'] == 'Pending'
            ]
        
        if not pending_orders:
            print("No pending orders")
            return
        
        for pending_order in pending_orders:
            pending_order['status'] = 'Processed'
            print(f"Processed: {pending_order['name']}")

        if prompt == 'y':
            pending_orders.clear

def necessity():

    nouns = ["sky", "river", "tree", "mountain", "dream", 
             "shadow", "whisper", "light", "night", "wind"]
    verbs = ["flows", "whispers", "shines", "dances", "sings", 
             "rests", "moves", "calls", "falls", "glows"]
    adjectives = ["silent", "golden", "gentle", "soft", "endless", 
                  "quiet", "bright", "dark", "peaceful", "lonely"]

    def generate_readable_poem(lines=4):
        poem = []
        for _ in range(lines):
            line = f"The {random.choice(adjectives)} {random.choice(nouns)} {random.choice(verbs)}."
            poem.append(line)
        return '\n'.join(poem)

    num_files = 50

    for i in range(1, num_files + 1):
        file_name = f"readable_poem_{i}.txt"
        with open(file_name, "w") as file:
            readable_poem = generate_readable_poem(lines=4)
            file.write(readable_poem)
        print(f"{file_name} has been created!")
