# PROJECT_CONTEXT: StockSmart

> **Master Context Document**
> _Last Updated: 2025-12-21_

## 1. Project Vision

**StockSmart** is a streamlined inventory management and ordering application designed specifically for high-pace Ramen shops.

- **Problem**: Manual stock taking is slow, error-prone, and disconnected from ordering.
- **Solution**: A fast, offline-first mobile app that allows rapid inventory counting, visualizes shortages against "Par Levels", and generates shopping lists automatically.

## 2. Technical Stack

- **Framework**: Flutter (Targeting Web & Mobile).
- **Language**: Dart.
- **State Management**: `Provider` (Simple, scalable dependency injection).
- **Local Database**: `Hive` (NoSQL, Key-Value) - Used as the "Source of Truth" for speed and offline capability.
- **Remote Database**: `Firebase Firestore` (Document Store) - Used for background sync and backup.
- **Authentication**: `Firebase Auth`.

## 3. Architecture Phase: MVP (Iterative)

The app follows a **Repository Pattern**:
`UI` -> `Provider` -> `Repository` -> `Local Storage (Hive)` [-> `Remote (Firestore)`]

- **Offline-First**: The UI always displays data from Hive. Sync actions happen in the background.
- **Guest Mode**: Users can essentially use the full app without logging in (local only).

## 4. Current Data Schema

### **GroceryItem**

- `id`: UUID
- `name`: String
- `categoryIds`: List<String>
- `defaultSupplierId`: String? (Link to Supplier)
- `unit`: String
- `parLevel`: double
- `currentQuantity`: double
- `lastUpdated`: DateTime

### **Supplier** (MVP)

- `id`: UUID
- `name`: String
- `isActive`: bool
- _Note: No pricing, contacts, or addresses for MVP._

### **ShoppingList (Cart)**

- `id`: UUID
- `status`: 'active' | 'archived' (Only one active at a time)
- `createdAt`: DateTime
- `completedAt`: DateTime?
- `globalNote`: String?

### **CartItem**

- `itemId`: String (Link to GroceryItem)
- `listId`: String
- `supplierId`: String (Defaults to item's default, overridable)
- `quantity`: double
- `unit`: String
- `status`: 'pending' | 'bought' | 'skipped' | 'unavailable'
- `note`: String? (Per-item note)
- `updatedAt`: DateTime

## 5. Core Concepts & Rules

### **Cart Philosophy**

- **Single Active Cart**: Only one "Active" cart exists at a time. Previous carts are "Archived".
- **Persistence**: Never auto-delete. Always work offline.
- **Structure**: Items are visually grouped by **Supplier**.

### **Supplier Rules**

- **Minimal Scope**: Used strictly for grouping and default ordering.
- **Override**: Changing a supplier in the cart does NOT affect the item's default supplier.

### **Sync & Conflict**

- **Hive First**: All writes go to local storage immediately.
- **Item-Level Conflict**: Latest update wins.
- **Guest Merge**: If a guest logs in, their local cart merges into the account's cart.

## 6. Implemented Features

### **A. Inventory Management**

- **Dynamic Tabs**: Categories are rendered as Tabs.
- **Global Search**: Search bar to filter items across all categories.
- **Multi-Category Support**: Items can appear in multiple tabs.
- **Item Manager**: Dedicated screen for CRUD operations.

### **B. Stock Taking**

- **Steppers**: +/- buttons for quick adjustments.
- **Visual Cues**: Red border for Low Stock (below Par).
- **"In Stock" Label**: Clear distinction between current vs par.

### **C. Smart Cart System (Refactoring)**

- _(Planned)_: Group by Supplier, Status tracking (Pending/Bought), Single Active List.
- **Current State**: Basic list generation and manual add.

## 7. User Workflow

1.  **Count**: Staff walks through kitchen, updating stock numbers.
2.  **Order**: Staff adds low-stock items to the **Single Active Cart** (Manual or Auto-Suggest).
3.  **Review**: Manager opens Cart, sees items **Grouped by Supplier**, and marks them 'Bought' or 'Skipped'.
4.  **Archive**: Once done, the cart is archived, and a new one can be started.

## 8. Roadmap (Next Steps)

- [ ] **Implement Supplier System**: Model, Repo, and Assignment UI.
- [ ] **Refactor Cart**: Enforce "active/archived" status and Supplier grouping.
- [ ] **Cart Item States**: Add UI for 'bought', 'skipped', 'unavailable'.
