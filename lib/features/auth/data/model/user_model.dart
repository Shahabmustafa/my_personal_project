class UserModel {
  final String id;
  final String username;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final List<String> branchIds;
  final List<String> warehouseIds;
  final List<String> headOfficeIds;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber = '',
    required this.role,
    this.isActive = true,
    this.branchIds = const [],
    this.warehouseIds = const [],
    this.headOfficeIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parseBranchIds(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) => e is Map ? e['branch_id']?.toString() ?? '' : e.toString())
            .where((id) => id.isNotEmpty)
            .toList();
      }
      return [];
    }

    List<String> parseWarehouseIds(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) => e is Map ? e['warehouse_id']?.toString() ?? '' : e.toString())
            .where((id) => id.isNotEmpty)
            .toList();
      }
      return [];
    }

    List<String> parseHeadOfficeIds(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) => e is Map ? e['head_office_id']?.toString() ?? '' : e.toString())
            .where((id) => id.isNotEmpty)
            .toList();
      }
      return [];
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'salesman',
      isActive: json['is_active'] ?? true,
      branchIds: parseBranchIds(json['user_branches']),
      warehouseIds: parseWarehouseIds(json['user_warehouses']),
      headOfficeIds: parseHeadOfficeIds(json['user_head_offices']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'is_active': isActive,
      };

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isActive,
    List<String>? branchIds,
    List<String>? warehouseIds,
    List<String>? headOfficeIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      branchIds: branchIds ?? this.branchIds,
      headOfficeIds: headOfficeIds ?? this.headOfficeIds,
      warehouseIds: warehouseIds ?? this.warehouseIds,
    );
  }

  // ── Role checks ──────────────────────────────────────────────────────────
  bool get isSuperAdmin => role == 'superadmin';
  bool get isManager => role == 'manager';
  bool get isSupervisor => role == 'supervisor';
  bool get isWarehouseManager => role == 'warehouse_manager';
  bool get isInventoryManager => role == 'inventory_manager';
  bool get isCashier => role == 'cashier';
  bool get isSalesman => role == 'salesman';

  // Supervisor ko branches/warehouses assign ho sakte hain (superadmin ke
  // zariye), lekin supervisor khud kisi user ko manage/assign nahi kar sakta.
  bool get canManageUsers => isSuperAdmin;
  bool get canManageBranches => isSuperAdmin;
  bool get canManageWarehouses => isSuperAdmin;
  bool get canManageHeadOffice => isSuperAdmin;
  bool get canManageStock =>
      isSuperAdmin || isManager || isWarehouseManager || isInventoryManager;
  bool get canProcessPayment =>
      isSuperAdmin || isManager || isCashier;
  bool get canCreateSales =>
      isSuperAdmin || isManager || isCashier || isSalesman;
  bool get canViewReports => isSuperAdmin || isManager;

  String get roleDisplayName {
    const map = {
      'superadmin': 'Super Admin',
      'manager': 'Manager',
      'supervisor': 'Supervisor',
      'warehouse_manager': 'Warehouse Manager',
      'inventory_manager': 'Inventory Manager',
      'cashier': 'Cashier',
      'salesman': 'Salesman',
    };
    return map[role] ?? role;
  }
}
