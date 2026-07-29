# StockSmart: Ramen Shop Inventory & Grocery App

A specialized inventory management system built for Ramen shops to streamline stock checks and automate ordering.

## 🚀 Application Context
**StockSmart** resolves the chaos of manual inventory taking (often done on paper or mental notes) by providing a fast, tailored mobile/web app. It helps staff:
1.  **Count Stock** efficiently using simple +/- steppers.
2.  **Identify Shortages** by comparing current stock vs. "Par Levels" (Minimum required stock).
3.  **Automate Ordering** by generating shopping lists based on missing quantities.

## ✨ Key Features
*   **Inventory Dashboard**:
    *   **Dynamic Categories**: Organize items by tabs (e.g., Produce, Meat, Garnish). fully adjustable.
    *   **Search**: Instantly find any item across all categories.
    *   **Visual Stock**: "In Stock" indicators and color-coded warnings (Red border = Low Stock).
    *   **Quick Edits**: Adjust quantities with buttons or type numbers directly.
*   **Item Management**:
    *   **Flexible Inventory**: Add new items, delete old ones, or edit details (Par level, Unit, Name).
    *   **Multi-Category**: Items can belong to multiple categories (e.g., "Egg" in both *Prep* and *Toppings*).
    *   **Units**: Supports kg, g, L, pcs, box, bunch, tray, roll, pack, etc.
*   **Smart Cart System**:
    *   **One-Tap Add**: Click the cart icon on any item to add it to the shopping list.
    *   **Status Indicators**: Icon turns green/checked if the item is already in the cart.
    *   **Smart Quantity**: Prompts "How much to order?" (Defaults to 1, or asks for specific amount).
    *   **Auto-Generation**: Can auto-fill a list based on (Par Level - Current Stock).
*   **Category Management**:
    *   Create, Rename, and Delete categories to fit the restaurant's changing menu.
*   **Offline-First**:
    *   Works without internet (Guest Mode).
    *   Syncs to Cloud (Firebase) when online (Login required).

## 🔄 Workflow

### 1. Daily Inventory Check (The "Oppening")
*   Staff opens the app and walks through the kitchen.
*   They tap through tabs (*Produce, Meat, etc.*).
*   For each item, they adjust the **Current Quantity** to match reality.
*   *Tip*: Use the search bar to jump to specific items.

### 2. Identifying Needs
*   As stock numbers drop below the **Par Level**, items highlight in **RED**.
*   This gives an instant visual cue of what needs to be ordered.

### 3. Creating the Order
*   **Manual**: Staff taps the **Cart Icon** on low-stock items and enters the quantity needed.
*   **Auto (Future)**: The app can auto-generate the list for everything below Par.

### 4. Shopping / Ordering
*   Management opens the **Cart Screen**.
*   The list is grouped by Supplier (e.g., *Makro, Vegetable Market*).
*   Items are checked off as they are purchased.

## 🛠 Technical Stack
*   **Framework**: Flutter (Web & Mobile).
*   **State Management**: Provider.
*   **Local DB**: Hive (for speed and offline support).
*   **Cloud DB**: Firebase Firestore (for sync and backup).
*   **Auth**: Firebase Auth (Anonymous & Email).

## Getting Started
To run locally:
```bash
flutter run -d chrome
```
*Note: If Firebase is not configured, use "Guest Mode" to run offline.*
