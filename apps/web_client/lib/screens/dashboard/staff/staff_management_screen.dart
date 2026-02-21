import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get current user's tenant_id
      final userProfile = await _supabase
          .from('users')
          .select('tenant_id')
          .eq('id', user.id)
          .maybeSingle();

      final tenantId = userProfile?['tenant_id'];
      if (tenantId == null) return;

      // Fetch staff members (include phone and avatar_url)
      final staffResponse = await _supabase
          .from('users')
          .select('id, full_name, email, phone, role, avatar_url, created_at')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      // Fetch pending invitations
      final invitesResponse = await _supabase
          .from('staff_invitations')
          .select()
          .eq('tenant_id', tenantId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(staffResponse);
          _pendingInvites = List<Map<String, dynamic>>.from(invitesResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading staff: $e')));
      }
    }
  }

  /// Returns display-friendly role label.
  /// Maps 'tenant_admin' to 'Owner'.
  String _roleLabel(String role) {
    switch (role) {
      case 'tenant_admin':
        return 'Owner';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Cashier';
      case 'rider':
        return 'Rider';
      case 'staff':
        return 'Staff';
      default:
        return role[0].toUpperCase() + role.substring(1);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Staff Member'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'rider', child: Text('Rider')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final email = emailController.text.trim();
                final name = nameController.text.trim();
                if (email.isEmpty || name.isEmpty) return;

                try {
                  final user = _supabase.auth.currentUser;
                  if (user == null) return;

                  final userProfile = await _supabase
                      .from('users')
                      .select('tenant_id')
                      .eq('id', user.id)
                      .single();

                  await _supabase.from('staff_invitations').insert({
                    'email': email,
                    'full_name': name,
                    'role': selectedRole,
                    'tenant_id': userProfile['tenant_id'],
                    'invited_by': user.id,
                    'status': 'pending',
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadStaffData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent to $email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff Management',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_staffList.length} members · ${_pendingInvites.length} pending invites',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.lightMutedForeground,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Staff'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pending Invites
                        if (_pendingInvites.isNotEmpty) ...[
                          Text(
                            'Pending Invitations',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._pendingInvites.map(
                            (invite) =>
                                _InviteCard(invite: invite, isDark: isDark),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Active Staff
                        Text(
                          'Active Staff',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_staffList.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: isDark
                                        ? AppColors.darkMutedForeground
                                        : AppColors.lightMutedForeground,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No staff members yet'),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Invite team members to get started',
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isDesktop)
                          _buildStaffTable(theme, isDark)
                        else
                          ..._staffList.map(
                            (staff) => _StaffCard(
                              staff: staff,
                              isDark: isDark,
                              roleLabel: _roleLabel,
                              getInitials: _getInitials,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Desktop DataTable view
  Widget _buildStaffTable(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith(
            (_) => isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.grey.withOpacity(0.06),
          ),
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: const [
            DataColumn(label: Text('Staff')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Role')),
          ],
          rows: _staffList.map((staff) {
            final role = (staff['role'] as String?) ?? 'staff';
            final name = staff['full_name'] ?? 'Unknown';
            final email = staff['email'] ?? '';
            final phone = staff['phone'] ?? '-';
            final avatarUrl = staff['avatar_url'] as String?;

            return DataRow(
              cells: [
                // Staff name + avatar
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.15,
                        ),
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                _getInitials(name),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(email)),
                DataCell(Text(phone)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _roleColor(role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: TextStyle(
                        color: _roleColor(role),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'tenant_admin':
        return Colors.amber[700]!;
      case 'manager':
        return Colors.blue;
      case 'cashier':
        return Colors.teal;
      case 'rider':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// Mobile staff card with avatar, name, email, phone, and role
class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final bool isDark;
  final String Function(String) roleLabel;
  final String Function(String) getInitials;

  const _StaffCard({
    required this.staff,
    required this.isDark,
    required this.roleLabel,
    required this.getInitials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = (staff['role'] as String?) ?? 'staff';
    final name = staff['full_name'] ?? 'Unknown';
    final email = staff['email'] ?? '';
    final phone = staff['phone'] ?? '-';
    final avatarUrl = staff['avatar_url'] as String?;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      getInitials(name),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.lightMutedForeground,
                    ),
                  ),
                  if (phone != '-') ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.lightMutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleLabel(role),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final bool isDark;

  const _InviteCard({required this.invite, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.15),
          child: const Icon(Icons.mail_outline, color: Colors.orange),
        ),
        title: Text(
          invite['full_name'] ?? invite['email'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(invite['email'] ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
