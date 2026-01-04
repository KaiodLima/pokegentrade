import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
  static const Map<String, Map<String, String>> _strings = {
    'pt': {
      'publicRooms': 'Salas Públicas',
      'admin': 'Admin',
      'profile': 'Perfil',
      'diagnostics': 'Diagnóstico',
      'settings': 'Configurações',
      'logout': 'Sair',
      'openRealtimeChat': 'Abrir Chat em Tempo Real',
      'contacts': 'Contatos (DM)',
      'inboxDMs': 'Inbox DMs',
      'marketplace': 'Marketplace',
      'message': 'Mensagem',
      'sending': 'Enviando...',
      'send': 'Enviar',
      'tryAgain': 'Tentar novamente',
      'connected': 'Conectado',
      'disconnected': 'Desconectado',
      'newConnection': 'Nova conexão',
      'retryConnect': 'Tentar reconectar',
      'loadMore': 'Carregar mais',
      'unreadOnly': 'Apenas não lidas',
      'unreadFirst': 'Não lidas primeiro',
      'mostRecent': 'Mais recentes',
    'searchByNameOrId': 'Buscar por nome ou ID',
    'markAllRead': 'Marcar todas lidas',
    'email': 'Email',
    'password': 'Senha',
    'entering': 'Entrando...',
    'enter': 'Entrar',
    'createAccount': 'Criar nova conta',
    'forgotPassword': 'Esqueci minha senha',
    'loginTimeout': 'Tempo esgotado, verifique sua conexão',
    'loginFailed': 'Falha no login',
    'provideEmailPassword': 'Informe email e senha',
    'disclaimer': 'Plataforma independente, sem afiliação a jogos oficiais.',
    'attachments': 'Anexos',
    'copyLink': 'Copiar link',
    'approve': 'Aprovar',
    'complete': 'Concluir',
    'suspendAuthor': 'Suspender Autor',
    'adDetail': 'Detalhe do Anúncio',
    'adNotFound': 'Anúncio não encontrado',
    'status': 'Status',
    'type': 'Tipo',
    'all': 'Todos',
    'pending': 'Pendente',
    'approved': 'Aprovado',
    'completed': 'Concluído',
    'minPrice': 'Preço min',
    'maxPrice': 'Preço max',
    'newAd': 'Novo Anúncio',
    'sale': 'Venda',
    'buy': 'Compra',
    'trade': 'Troca',
    'title': 'Título',
    'description': 'Descrição',
    'price': 'Preço',
    'selectFiles': 'Selecionar Arquivos',
    'selectedLabel': 'selecionados',
    'requests': 'Requisições',
    'timeouts': 'Timeouts',
    'networkErrors': 'Erros de rede',
    'update': 'Atualizar',
    'reset': 'Resetar',
    'edit': 'Editar',
    'delete': 'Excluir',
    'save': 'Salvar',
    'updated': 'Atualizado',
      'deleted': 'Excluído',
      'failUpdate': 'Falha ao atualizar',
      'failDelete': 'Falha ao excluir',
      'confirmDelete': 'Confirmar exclusão?',
      'confirm': 'Confirmar',
      'cancel': 'Cancelar',
      'confirmApprove': 'Confirmar aprovação?',
      'confirmComplete': 'Confirmar conclusão?',
      'confirmSuspend': 'Confirmar suspensão?',
      'read': 'Lida',
      'delivered': 'Enviada',
      'editMessage': 'Editar mensagem',
      'edited': 'Editada',
      'home': 'Início',
      'selectPhoto': 'Selecionar foto',
      'selectAvatar': 'Selecionar avatar',
      'createRoom': 'Criar sala',
      'editRoom': 'Editar sala',
      'newUser': 'Novo usuário',
    },
  'en': {
      'publicRooms': 'Public Rooms',
      'admin': 'Admin',
      'profile': 'Profile',
      'diagnostics': 'Diagnostics',
      'settings': 'Settings',
      'logout': 'Logout',
      'openRealtimeChat': 'Open Live Chat',
      'contacts': 'Contacts (DM)',
      'inboxDMs': 'DM Inbox',
      'marketplace': 'Marketplace',
      'message': 'Message',
      'sending': 'Sending...',
      'send': 'Send',
      'tryAgain': 'Try again',
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'newConnection': 'New connection',
      'retryConnect': 'Retry connect',
      'loadMore': 'Load more',
      'unreadOnly': 'Unread only',
      'unreadFirst': 'Unread first',
      'mostRecent': 'Most recent',
    'searchByNameOrId': 'Search by name or ID',
    'markAllRead': 'Mark all as read',
    'email': 'Email',
    'password': 'Password',
    'entering': 'Signing in...',
    'enter': 'Sign in',
    'createAccount': 'Create new account',
    'forgotPassword': 'Forgot my password',
    'loginTimeout': 'Timeout, please check your connection',
    'loginFailed': 'Login failed',
    'provideEmailPassword': 'Provide email and password',
    'disclaimer': 'Independent platform, no affiliation with official games.',
    'attachments': 'Attachments',
    'copyLink': 'Copy link',
    'approve': 'Approve',
    'complete': 'Complete',
    'suspendAuthor': 'Suspend Author',
    'adDetail': 'Ad Detail',
    'adNotFound': 'Ad not found',
    'status': 'Status',
    'type': 'Type',
    'all': 'All',
    'pending': 'Pending',
    'approved': 'Approved',
    'completed': 'Completed',
    'minPrice': 'Min price',
    'maxPrice': 'Max price',
    'newAd': 'New Ad',
    'sale': 'Sale',
    'buy': 'Buy',
    'trade': 'Trade',
    'title': 'Title',
    'description': 'Description',
    'price': 'Price',
    'selectFiles': 'Select Files',
    'selectedLabel': 'selected',
    'requests': 'Requests',
    'timeouts': 'Timeouts',
    'networkErrors': 'Network errors',
    'update': 'Update',
    'reset': 'Reset',
    'edit': 'Edit',
    'delete': 'Delete',
    'save': 'Save',
    'updated': 'Updated',
      'deleted': 'Deleted',
      'failUpdate': 'Failed to update',
      'failDelete': 'Failed to delete',
      'confirmDelete': 'Confirm deletion?',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'confirmApprove': 'Confirm approval?',
      'confirmComplete': 'Confirm completion?',
      'confirmSuspend': 'Confirm suspension?',
      'read': 'Read',
      'delivered': 'Delivered',
      'editMessage': 'Edit message',
      'edited': 'Edited',
      'home': 'Home',
      'selectPhoto': 'Select photo',
      'selectAvatar': 'Select avatar',
      'createRoom': 'Create room',
      'editRoom': 'Edit room',
      'newUser': 'New user',
    },
};
  String _t(String key) => _strings[locale.languageCode]?[key] ?? _strings['pt']![key]!;
  static AppLocalizations of(BuildContext context) {
    final inst = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return inst ?? AppLocalizations(const Locale('pt'));
  }
  String get publicRooms => _t('publicRooms');
  String get admin => _t('admin');
  String get profile => _t('profile');
  String get diagnostics => _t('diagnostics');
  String get settings => _t('settings');
  String get logout => _t('logout');
  String get openRealtimeChat => _t('openRealtimeChat');
  String get contacts => _t('contacts');
  String get inboxDMs => _t('inboxDMs');
  String get marketplace => _t('marketplace');
  String get message => _t('message');
  String get sending => _t('sending');
  String get send => _t('send');
  String get tryAgain => _t('tryAgain');
  String get connected => _t('connected');
  String get disconnected => _t('disconnected');
  String get newConnection => _t('newConnection');
  String get retryConnect => _t('retryConnect');
  String get loadMore => _t('loadMore');
  String get unreadOnly => _t('unreadOnly');
  String get unreadFirst => _t('unreadFirst');
  String get mostRecent => _t('mostRecent');
  String get searchByNameOrId => _t('searchByNameOrId');
  String get markAllRead => _t('markAllRead');
  String get email => _t('email');
  String get password => _t('password');
  String get entering => _t('entering');
  String get enter => _t('enter');
  String get createAccount => _t('createAccount');
  String get forgotPassword => _t('forgotPassword');
  String get loginTimeout => _t('loginTimeout');
  String get loginFailed => _t('loginFailed');
  String get provideEmailPassword => _t('provideEmailPassword');
  String get disclaimer => _t('disclaimer');
  String get attachments => _t('attachments');
  String get copyLink => _t('copyLink');
  String get approve => _t('approve');
  String get complete => _t('complete');
  String get suspendAuthor => _t('suspendAuthor');
  String get adDetail => _t('adDetail');
  String get adNotFound => _t('adNotFound');
  String get status => _t('status');
  String get type => _t('type');
  String get all => _t('all');
  String get pending => _t('pending');
  String get approved => _t('approved');
  String get completed => _t('completed');
  String get minPrice => _t('minPrice');
  String get maxPrice => _t('maxPrice');
  String get newAd => _t('newAd');
  String get sale => _t('sale');
  String get buy => _t('buy');
  String get trade => _t('trade');
  String get title => _t('title');
  String get description => _t('description');
  String get price => _t('price');
  String get selectFiles => _t('selectFiles');
  String get selectedLabel => _t('selectedLabel');
  String get requests => _t('requests');
  String get timeouts => _t('timeouts');
  String get networkErrors => _t('networkErrors');
  String get update => _t('update');
  String get reset => _t('reset');
  String get edit => _t('edit');
  String get delete => _t('delete');
  String get save => _t('save');
  String get updated => _t('updated');
  String get deleted => _t('deleted');
  String get failUpdate => _t('failUpdate');
  String get failDelete => _t('failDelete');
  String get confirmDelete => _t('confirmDelete');
  String get confirm => _t('confirm');
  String get cancel => _t('cancel');
  String get confirmApprove => _t('confirmApprove');
  String get confirmComplete => _t('confirmComplete');
  String get confirmSuspend => _t('confirmSuspend');
  String get read => _t('read');
  String get delivered => _t('delivered');
  String get editMessage => _t('editMessage');
  String get edited => _t('edited');
  String get home => _t('home');
  String get selectPhoto => _t('selectPhoto');
  String get selectAvatar => _t('selectAvatar');
  String get createRoom => _t('createRoom');
  String get editRoom => _t('editRoom');
  String get newUser => _t('newUser');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['pt', 'en'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();
}
