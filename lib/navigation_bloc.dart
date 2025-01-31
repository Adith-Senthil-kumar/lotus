import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(HomeState()) {
    // Map navigation events to their respective states
    on<NavigateToHome>((event, emit) => emit(HomeState()));
    on<NavigateToTenant>((event, emit) => emit(TenantState()));
    on<NavigateToRooms>((event, emit) => emit(RoomsState()));
    on<NavigateToEB>((event, emit) => emit(EBState()));
  }
}