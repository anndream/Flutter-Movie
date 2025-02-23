import 'dart:ui';
import 'package:fish_redux/fish_redux.dart';
import 'package:movie/globalbasestate/state.dart';
import 'package:movie/models/base_api_model/braintree_customer.dart';
import 'package:movie/models/base_api_model/transaction.dart';
import 'package:movie/models/app_user.dart';

class PaymentPageState implements GlobalBaseState, Cloneable<PaymentPageState> {
  TransactionModel transactions;
  BraintreeCustomer customer;
  @override
  PaymentPageState clone() {
    return PaymentPageState()
      ..transactions = transactions
      ..customer = customer
      ..user = user;
  }

  @override
  Locale locale;

  @override
  Color themeColor;

  @override
  AppUser user;
}

PaymentPageState initState(Map<String, dynamic> args) {
  return PaymentPageState();
}
