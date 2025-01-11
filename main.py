from order import Order, necessity

def show_menu():
    print("""
=== order Management System ===
1. Add order
2. Display orders
3. Display Grand Total
4. Process orders
5. Exit
""")

def get_order_details():
    name = input("Enter product name: ")
    while True:
        try:
            quantity = int(input("Enter quantity: "))
            price = float(input("Enter price: "))
            return name, quantity, price
        except ValueError:
            print("Please enter valid numbers for quantity and price.")

def process():
    order_system = Order
    necessity()
    
    menu_actions = {
        "1": lambda: order_system.add_order(*get_order_details()),
        "2": order_system.display_orders,
        "3": order_system.display_grand_total,
    }

    while True:
        show_menu()
        choice = input("Enter your choice: ")

        if choice == "5": 
            print("Exiting program...")
            break
        action = menu_actions.get(choice)

        if action:
            action()

        if choice == "4":
            order_system.process_orders()
        else:
            print("Invalid choice. Please try again.")     

process()