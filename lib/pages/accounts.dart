import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:chopper/chopper.dart' show Response;

import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/pages/navigation.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: 4);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavPageElements>().setAppBarBottom(TabBar(
            isScrollable: true,
            controller: _tabController,
            tabs: <Tab>[
              Tab(text: S.of(context).accountsLabelAsset),
              Tab(text: S.of(context).accountsLabelExpense),
              Tab(text: S.of(context).accountsLabelRevenue),
              Tab(text: S.of(context).accountsLabelLiabilities),
            ],
          ));
      // Call once to set fab/page actions
      _handleTabChange();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();

    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      debugPrint("_handleTabChange()");
    }
  }

  late List<Tab> tabs;

  static const List<Widget> tabPages = <Widget>[
    AccountDetails(accountType: AccountTypeFilter.asset),
    AccountDetails(accountType: AccountTypeFilter.expense),
    AccountDetails(accountType: AccountTypeFilter.revenue),
    AccountDetails(accountType: AccountTypeFilter.liabilities),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint("accounts build(), tab ${_tabController.index}");
    return TabBarView(
      controller: _tabController,
      children: tabPages,
    );
  }
}

class AccountDetails extends StatefulWidget {
  const AccountDetails({
    Key? key,
    required this.accountType,
  }) : super(key: key);

  final AccountTypeFilter accountType;

  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails>
    with AutomaticKeepAliveClientMixin {
  Future<AccountArray> _fetchData() async {
    final FireflyIii api = context.read<FireflyService>().api;

    final Response<AccountArray> respAccounts =
        await api.v1AccountsGet(type: widget.accountType);
    if (!respAccounts.isSuccessful || respAccounts.body == null) {
      if (context.mounted) {
        throw Exception(
          S
              .of(context)
              .errorAPIInvalidResponse(respAccounts.error?.toString() ?? ""),
        );
      } else {
        throw Exception(
          "[nocontext] Invalid API response: ${respAccounts.error}",
        );
      }
    }

    return Future<AccountArray>.value(respAccounts.body);
  }

  Future<void> _refreshStats() async {
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint("accounts_detail build()");

    return RefreshIndicator(
        onRefresh: () => _refreshStats(),
        child: FutureBuilder<AccountArray>(
          future: _fetchData(),
          builder:
              (BuildContext context, AsyncSnapshot<AccountArray> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              if (snapshot.data!.data.isEmpty) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        S.of(context).homePiggyNoAccounts,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Icon(
                        Icons.savings_outlined,
                        size: 200,
                      ),
                      Text(
                        S.of(context).homePiggyNoAccountsSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                cacheExtent: 1000,
                padding: const EdgeInsets.all(8),
                children: <Widget>[
                  ...snapshot.data!.data.map(
                    (AccountRead account) {
                      return ListTile(
                        title: Text(account.attributes.name),
                      );
                    },
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text(snapshot.error!.toString());
            } else {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ));
  }
}