# API do Motorista - Documentação para App Flutter

## Base URL
```
http://localhost:5000/api/v1/driver

a api esta definia em lib/functions.dart na linha 62
a chave maps android esta na linha 64

```

## Autenticação
A API usa **sessões** para autenticação. Após o login, um cookie de sessão é retornado e deve ser incluído em todas as requisições subsequentes.

**Flutter/Dart**: Use o pacote `dio` ou `http` com suporte a cookies.

```dart
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

final dio = Dio();
final cookieJar = CookieJar();
dio.interceptors.add(CookieManager(cookieJar));
```

---

## Endpoints Disponíveis

### 1. Registro de Motorista

**Endpoint:** `POST /api/v1/driver/register`

**Descrição:** Registra um novo motorista no sistema. O motorista será criado com status `approve: false` e precisará aguardar aprovação do administrador.

**Request Body:**
```json
{
  "name": "João Silva",
  "cpf": "123.456.789-00",
  "mobile": "11999999999",
  "email": "joao@email.com",
  "password": "senha123",
  "serviceLocationId": "uuid-opcional",
  "vehicleTypeId": "uuid-opcional",
  "carMake": "Toyota",
  "carModel": "Corolla",
  "carNumber": "ABC-1234",
  "carColor": "Branco",
  "carYear": "2020",
  "deviceToken": "fcm_token_aqui",
  "loginBy": "android"
}
```

**Campos Obrigatórios:**
- `name` - Nome completo do motorista
- `mobile` - Telefone (apenas números)
- `password` - Senha (mínimo 6 caracteres recomendado)

**Campos Opcionais:**
- `cpf` - CPF do motorista
- `email` - Email do motorista
- `serviceLocationId` - ID da cidade/localização de serviço
- `vehicleTypeId` - ID do tipo de veículo (Moto, Carro, Van, etc)
- `carMake` - Marca do veículo
- `carModel` - Modelo do veículo
- `carNumber` - Placa do veículo
- `carColor` - Cor do veículo
- `carYear` - Ano do veículo
- `deviceToken` - Token FCM para notificações push
- `loginBy` - Plataforma (android, ios)

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Motorista registrado com sucesso. Aguarde aprovação do administrador.",
  "data": {
    "id": "uuid-do-motorista",
    "name": "João Silva",
    "mobile": "11999999999",
    "email": "joao@email.com",
    "approve": false
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Nome, telefone e senha são obrigatórios"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Já existe um motorista cadastrado com este telefone"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> registerDriver() async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/register',
      data: {
        'name': 'João Silva',
        'mobile': '11999999999',
        'password': 'senha123',
        'deviceToken': fcmToken,
        'loginBy': 'android',
      },
    );

    if (response.data['success']) {
      print('Registro realizado: ${response.data['message']}');
      // Redirecionar para tela de aguardando aprovação
    }
  } on DioException catch (e) {
    print('Erro: ${e.response?.data['message']}');
  }
}
```

---

### 2. Login de Motorista

**Endpoint:** `POST /api/v1/driver/login`

**Descrição:** Autentica o motorista e cria uma sessão. Retorna os dados do motorista logado.

**Request Body:**
```json
{
  "mobile": "11999999999",
  "password": "senha123",
  "deviceToken": "fcm_token_aqui",
  "loginBy": "android"
}
```

**Campos Obrigatórios:**
- `mobile` - Telefone do motorista
- `password` - Senha

**Campos Opcionais:**
- `deviceToken` - Token FCM para notificações
- `loginBy` - Plataforma (android, ios)

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login realizado com sucesso",
  "data": {
    "id": "uuid-do-motorista",
    "name": "João Silva",
    "mobile": "11999999999",
    "email": "joao@email.com",
    "profilePicture": "/uploads/foto.jpg",
    "active": true,
    "approve": true,
    "available": false,
    "rating": "4.8",
    "vehicleTypeId": "uuid-tipo-veiculo",
    "carMake": "Toyota",
    "carModel": "Corolla",
    "carNumber": "ABC-1234",
    "carColor": "Branco",
    "uploadedDocuments": true
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "message": "Telefone ou senha incorretos"
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Sua conta foi desativada. Entre em contato com o suporte."
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<Map<String, dynamic>?> loginDriver(String mobile, String password) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/login',
      data: {
        'mobile': mobile,
        'password': password,
        'deviceToken': fcmToken,
        'loginBy': Platform.isAndroid ? 'android' : 'ios',
      },
    );

    if (response.data['success']) {
      // Salvar dados do motorista localmente (SharedPreferences)
      final driver = response.data['data'];
      await saveDriverData(driver);
      return driver;
    }
  } on DioException catch (e) {
    print('Erro no login: ${e.response?.data['message']}');
  }
  return null;
}
```

---

### 3. Obter Dados do Motorista Logado

**Endpoint:** `GET /api/v1/driver`

**Descrição:** Retorna os dados completos do motorista autenticado.

**Headers:**
```
Cookie: connect.sid=session_id_aqui
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-do-motorista",
    "name": "João Silva",
    "mobile": "11999999999",
    "email": "joao@email.com",
    "cpf": "12345678900",
    "profilePicture": "/uploads/foto.jpg",
    "active": true,
    "approve": true,
    "available": false,
    "rating": "4.8",
    "ratingTotal": "96.0",
    "noOfRatings": 20,
    "serviceLocationId": "uuid-cidade",
    "vehicleTypeId": "uuid-tipo-veiculo",
    "carMake": "Toyota",
    "carModel": "Corolla",
    "carNumber": "ABC-1234",
    "carColor": "Branco",
    "carYear": "2020",
    "uploadedDocuments": true,
    "latitude": "-23.550520",
    "longitude": "-46.633309"
  }
}
```

**Response (401 Unauthorized):**
```json
{
  "message": "Não autenticado"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<Map<String, dynamic>?> getDriverProfile() async {
  try {
    final response = await dio.get('http://localhost:5000/api/v1/driver');

    if (response.data['success']) {
      return response.data['data'];
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      // Sessão expirou, redirecionar para login
      print('Sessão expirada');
    }
  }
  return null;
}
```

---

### 4. Atualizar Perfil do Motorista

**Endpoint:** `POST /api/v1/driver/profile`

**Descrição:** Atualiza os dados do perfil do motorista. Suporta upload de foto de perfil.

**Content-Type:** `multipart/form-data`

**Form Data:**
- `name` (opcional) - Nome
- `email` (opcional) - Email
- `carMake` (opcional) - Marca do veículo
- `carModel` (opcional) - Modelo do veículo
- `carNumber` (opcional) - Placa
- `carColor` (opcional) - Cor
- `carYear` (opcional) - Ano
- `profile_picture` (opcional) - Arquivo de imagem (JPG, PNG, GIF, SVG - max 5MB)

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Perfil atualizado com sucesso",
  "data": {
    "id": "uuid-do-motorista",
    "name": "João Silva",
    "email": "joao@email.com",
    "profilePicture": "/uploads/12345-foto.jpg",
    "carMake": "Toyota",
    "carModel": "Corolla",
    "carNumber": "ABC-1234",
    "carColor": "Branco",
    "carYear": "2020"
  }
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> updateProfile({
  String? name,
  String? email,
  File? profileImage,
  String? carMake,
  String? carModel,
}) async {
  try {
    final formData = FormData();

    if (name != null) formData.fields.add(MapEntry('name', name));
    if (email != null) formData.fields.add(MapEntry('email', email));
    if (carMake != null) formData.fields.add(MapEntry('carMake', carMake));
    if (carModel != null) formData.fields.add(MapEntry('carModel', carModel));

    if (profileImage != null) {
      formData.files.add(MapEntry(
        'profile_picture',
        await MultipartFile.fromFile(profileImage.path),
      ));
    }

    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/profile',
      data: formData,
    );

    if (response.data['success']) {
      print('Perfil atualizado!');
    }
  } on DioException catch (e) {
    print('Erro: ${e.response?.data['message']}');
  }
}
```

---

### 5. Atualizar Localização do Motorista

**Endpoint:** `POST /api/v1/driver/location`

**Descrição:** Atualiza a localização GPS atual do motorista. Deve ser chamado periodicamente enquanto o motorista estiver online.

**Request Body:**
```json
{
  "latitude": -23.550520,
  "longitude": -46.633309
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Localização atualizada com sucesso"
}
```

**Exemplo em Flutter/Dart:**
```dart
import 'package:geolocator/geolocator.dart';

Future<void> updateLocation() async {
  try {
    // Obter localização atual
    final position = await Geolocator.getCurrentPosition();

    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/location',
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    );

    if (response.data['success']) {
      print('Localização atualizada');
    }
  } catch (e) {
    print('Erro ao atualizar localização: $e');
  }
}

// Atualizar localização a cada 10 segundos quando online
Timer.periodic(Duration(seconds: 10), (timer) {
  if (isDriverOnline) {
    updateLocation();
  }
});
```

---

### 6. Toggle Online/Offline

**Endpoint:** `POST /api/v1/driver/online-offline`

**Descrição:** Alterna o status de disponibilidade do motorista (online/offline). O motorista só pode ficar online se estiver aprovado e tiver documentos enviados.

**Request Body:**
```json
{
  "availability": 1
}
```

**Valores:**
- `1` ou `true` - Ficar online
- `0` ou `false` - Ficar offline

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Você está online",
  "data": {
    "available": true
  }
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Você precisa ser aprovado pelo administrador antes de ficar online"
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Você precisa enviar os documentos necessários antes de ficar online"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<bool> toggleOnlineStatus(bool goOnline) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/online-offline',
      data: {
        'availability': goOnline ? 1 : 0,
      },
    );

    if (response.data['success']) {
      print(response.data['message']);
      return response.data['data']['available'];
    }
  } on DioException catch (e) {
    // Mostrar mensagem de erro ao usuário
    showErrorDialog(e.response?.data['message']);
  }
  return false;
}
```

---

### 7. Logout

**Endpoint:** `POST /api/v1/driver/logout`

**Descrição:** Encerra a sessão do motorista e marca como offline.

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logout realizado com sucesso"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> logoutDriver() async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/logout',
    );

    if (response.data['success']) {
      // Limpar dados locais
      await clearDriverData();
      // Redirecionar para tela de login
      Navigator.pushReplacementNamed(context, '/login');
    }
  } catch (e) {
    print('Erro ao fazer logout: $e');
  }
}
```

---

## Fluxo Completo de Uso no App Flutter

### 1. Tela de Registro
```dart
1. Motorista preenche formulário
2. App chama POST /api/v1/driver/register
3. Se sucesso, mostrar mensagem "Aguardando aprovação"
4. Motorista aguarda admin aprovar no painel
```

### 2. Tela de Login
```dart
1. Motorista insere telefone e senha
2. App chama POST /api/v1/driver/login
3. Se sucesso, salvar dados do motorista localmente
4. Verificar campo approve:
   - Se approve = false: Mostrar tela "Aguardando aprovação"
   - Se approve = true: Redirecionar para dashboard
```

### 3. Dashboard (Tela Principal)
```dart
1. Mostrar informações do motorista
2. Toggle online/offline
3. Quando ficar online:
   - Iniciar atualização de localização a cada 10s
   - Escutar novas corridas (via Firebase ou WebSocket)
4. Quando ficar offline:
   - Parar atualização de localização
```

### 4. Perfil
```dart
1. Mostrar dados do motorista (GET /api/v1/driver)
2. Permitir edição de nome, email, foto
3. Permitir edição de dados do veículo
4. Salvar alterações (POST /api/v1/driver/profile)
```

---

## Tratamento de Erros

### Erros Comuns

| Status Code | Significado | Ação Recomendada |
|-------------|-------------|-------------------|
| 400 | Bad Request - Dados inválidos | Mostrar mensagem de erro do response |
| 401 | Não autenticado | Redirecionar para login |
| 403 | Não autorizado (conta desativada, não aprovado) | Mostrar mensagem específica |
| 404 | Não encontrado | Mostrar mensagem de erro |
| 500 | Erro no servidor | Mostrar "Erro ao processar. Tente novamente" |

### Exemplo de Interceptor para Erros
```dart
dio.interceptors.add(InterceptorsWrapper(
  onError: (DioException e, handler) async {
    if (e.response?.statusCode == 401) {
      // Sessão expirou, fazer logout
      await logoutDriver();
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Mostrar erro genérico
      showErrorSnackbar(e.response?.data['message'] ?? 'Erro desconhecido');
    }
    return handler.next(e);
  },
));
```

---

## 📦 Gerenciamento de Entregas

### 8. Listar Entregas Disponíveis

**Endpoint:** `GET /api/v1/driver/deliveries/available`

**Descrição:** Lista todas as entregas disponíveis (sem motorista atribuído) que o motorista pode aceitar.

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-da-entrega",
      "requestNumber": "REQ-1234567890-123",
      "customerName": "João Silva",
      "totalDistance": "5.2",
      "totalTime": "15",
      "requestEtaAmount": "25.50",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "pickAddress": "Rua A, 123 - Bairro X",
      "dropAddress": "Rua B, 456 - Bairro Y",
      "pickLat": "-23.550520",
      "pickLng": "-46.633309",
      "dropLat": "-23.562940",
      "dropLng": "-46.654460",
      "companyName": "Empresa ABC",
      "vehicleTypeName": "Moto"
    }
  ]
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<List<Delivery>> getAvailableDeliveries() async {
  try {
    final response = await dio.get(
      'http://localhost:5000/api/v1/driver/deliveries/available',
    );

    if (response.data['success']) {
      final deliveries = (response.data['data'] as List)
          .map((item) => Delivery.fromJson(item))
          .toList();
      return deliveries;
    }
  } on DioException catch (e) {
    print('Erro ao buscar entregas: ${e.response?.data['message']}');
  }
  return [];
}
```

---

### 9. Obter Entrega Atual

**Endpoint:** `GET /api/v1/driver/deliveries/current`

**Descrição:** Retorna a entrega atualmente em andamento do motorista (se houver).

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-da-entrega",
    "requestNumber": "REQ-123",
    "customerName": "João Silva",
    "isDriverStarted": true,
    "isDriverArrived": true,
    "isTripStart": true,
    "isCompleted": false,
    "totalDistance": "5.2",
    "totalTime": "15",
    "requestEtaAmount": "25.50",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "acceptedAt": "2024-01-15T10:35:00.000Z",
    "pickAddress": "Rua A, 123",
    "dropAddress": "Rua B, 456",
    "pickLat": "-23.550520",
    "pickLng": "-46.633309",
    "dropLat": "-23.562940",
    "dropLng": "-46.654460",
    "companyName": "Empresa ABC",
    "companyPhone": "11988887777",
    "vehicleTypeName": "Moto"
  }
}
```

**Response (404 Not Found):**
```json
{
  "message": "Você não tem nenhuma entrega em andamento"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<Delivery?> getCurrentDelivery() async {
  try {
    final response = await dio.get(
      'http://localhost:5000/api/v1/driver/deliveries/current',
    );

    if (response.data['success']) {
      return Delivery.fromJson(response.data['data']);
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      // Nenhuma entrega em andamento
      return null;
    }
  }
  return null;
}
```

---

### 10. Aceitar Entrega

**Endpoint:** `POST /api/v1/driver/deliveries/:id/accept`

**Descrição:** Motorista aceita uma entrega disponível. A entrega será atribuída ao motorista e a empresa receberá uma notificação em tempo real via Socket.IO.

**Path Parameter:**
- `:id` - UUID da entrega

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Entrega aceita com sucesso",
  "data": {
    "deliveryId": "uuid-da-entrega",
    "status": "accepted"
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Esta entrega já foi aceita por outro motorista"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<bool> acceptDelivery(String deliveryId) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/deliveries/$deliveryId/accept',
    );

    if (response.data['success']) {
      showSuccessSnackbar('Entrega aceita!');
      return true;
    }
  } on DioException catch (e) {
    showErrorSnackbar(e.response?.data['message'] ?? 'Erro ao aceitar entrega');
  }
  return false;
}
```

---

### 11. Rejeitar Entrega

**Endpoint:** `POST /api/v1/driver/deliveries/:id/reject`

**Descrição:** Motorista rejeita uma entrega disponível.

**Path Parameter:**
- `:id` - UUID da entrega

**Request Body (opcional):**
```json
{
  "reason": "Muito longe"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Entrega rejeitada"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> rejectDelivery(String deliveryId, {String? reason}) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/deliveries/$deliveryId/reject',
      data: reason != null ? {'reason': reason} : null,
    );

    if (response.data['success']) {
      showInfoSnackbar('Entrega rejeitada');
    }
  } on DioException catch (e) {
    print('Erro ao rejeitar: ${e.response?.data['message']}');
  }
}
```

---

### 12. Chegou no Local de Retirada

**Endpoint:** `POST /api/v1/driver/deliveries/:id/arrived-pickup`

**Descrição:** Marca que o motorista chegou no local de retirada. A empresa receberá notificação em tempo real.

**Path Parameter:**
- `:id` - UUID da entrega

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Status atualizado: Chegou para retirada"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> markArrivedAtPickup(String deliveryId) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/deliveries/$deliveryId/arrived-pickup',
    );

    if (response.data['success']) {
      showSuccessSnackbar('Status atualizado!');
    }
  } on DioException catch (e) {
    showErrorSnackbar(e.response?.data['message'] ?? 'Erro ao atualizar status');
  }
}
```

---

### 13. Retirou o Pedido

**Endpoint:** `POST /api/v1/driver/deliveries/:id/picked-up`

**Descrição:** Marca que o motorista retirou o pedido e está indo para o local de entrega.

**Path Parameter:**
- `:id` - UUID da entrega

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Status atualizado: Pedido retirado"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> markPickedUp(String deliveryId) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/deliveries/$deliveryId/picked-up',
    );

    if (response.data['success']) {
      showSuccessSnackbar('Pedido retirado! Indo para entrega...');
    }
  } on DioException catch (e) {
    showErrorSnackbar(e.response?.data['message'] ?? 'Erro ao atualizar status');
  }
}
```

---

### 14. Pedido Entregue

**Endpoint:** `POST /api/v1/driver/deliveries/:id/delivered`

**Descrição:** Marca que o motorista entregou o pedido ao destinatário.

**Path Parameter:**
- `:id` - UUID da entrega

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Status atualizado: Pedido entregue"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> markDelivered(String deliveryId) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/deliveries/$deliveryId/delivered',
    );

    if (response.data['success']) {
      showSuccessSnackbar('Pedido entregue com sucesso!');
    }
  } on DioException catch (e) {
    showErrorSnackbar(e.response?.data['message'] ?? 'Erro ao atualizar status');
  }
}
```

---

### 15. Finalizar Entrega

**Endpoint:** `POST /api/v1/driver/deliveries/:id/complete`

**Descrição:** Finaliza completamente a entrega. Marca como concluída.

**Path Parameter:**
- `:id` - UUID da entrega

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Entrega finalizada com sucesso"
}
```

**Exemplo em Flutter/Dart:**
```dart
Future<void> completeDelivery(String deliveryId) async {
  try {
    final response = await dio.post(
      'http://localhost:5000/api/v1/driver/deliveries/$deliveryId/complete',
    );

    if (response.data['success']) {
      showSuccessSnackbar('Entrega concluída!');
      // Redirecionar para tela de entregas disponíveis
      Navigator.pushReplacementNamed(context, '/available-deliveries');
    }
  } on DioException catch (e) {
    showErrorSnackbar(e.response?.data['message'] ?? 'Erro ao finalizar entrega');
  }
}
```

---

## 🔔 Sistema de Notificações Push (FCM)

### Configuração do Firebase Cloud Messaging

O sistema envia notificações push para o app do motorista quando:
- Uma nova entrega está disponível **dentro do raio de pesquisa configurado**
- A empresa cancela uma entrega
- Há atualizações importantes

**⚙️ Raio de Pesquisa e Timeouts:**

O sistema utiliza três configurações importantes que o admin pode ajustar no painel:

1. **Raio de Pesquisa (driver_search_radius)**: Apenas motoristas dentro deste raio (em km) do ponto de retirada recebem a notificação
   - Padrão: 10 km
   - A localização do motorista deve ser atualizada constantemente (endpoint `/location`)

2. **Tempo de Aceitação (driver_acceptance_timeout)**: Tempo que o motorista tem para aceitar a entrega
   - Padrão: 30 segundos
   - Enviado no campo `acceptanceTimeout` da notificação

3. **Tempo de Busca (min_time_to_find_driver)**: Tempo total que o sistema fica procurando motoristas
   - Padrão: 120 segundos
   - Enviado no campo `searchTimeout` da notificação

### Como Configurar Firebase (Passo a Passo)

**📋 Resumo do que você precisa:**
1. Criar projeto no Firebase Console
2. Registrar app Android e iOS
3. Baixar arquivos de configuração
4. Obter credenciais para o backend
5. Configurar no app Flutter

---

#### **Passo 1: Criar Projeto Firebase**

1. Acesse: [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Clique em **"Adicionar projeto"**
3. Nome do projeto: "Fretus Delivery" (ou outro nome)
4. Clique em **"Criar projeto"**
5. Aguarde a criação e clique em **"Continuar"**

---

#### **Passo 2: Registrar App Android**

1. No Firebase Console, clique no ícone **Android** (robot)
2. **Nome do pacote**: `com.seudominio.fretus` (mesmo do seu `build.gradle`)
3. **Apelido**: "Fretus Driver Android"
4. Clique em **"Registrar app"**
5. **Baixe o `google-services.json`** ⬇️
6. Clique em **"Próximo"** até finalizar

**Onde colocar:** `android/app/google-services.json`

---

#### **Passo 3: Registrar App iOS**

1. No Firebase Console, clique no ícone **iOS** (Apple)
2. **Bundle ID**: `com.seudominio.fretus` (mesmo do Info.plist)
3. **Apelido**: "Fretus Driver iOS"
4. Clique em **"Registrar app"**
5. **Baixe o `GoogleService-Info.plist`** ⬇️
6. Clique em **"Próximo"** até finalizar

**Onde colocar:** Adicionar via Xcode ao projeto `ios/Runner`

---

#### **Passo 4: Obter Credenciais do Backend**

Estas credenciais serão usadas no **painel admin** para enviar notificações:

1. Firebase Console → ⚙️ **Configurações do projeto**
2. Aba **"Contas de serviço"** (Service Accounts)
3. Clique em **"Gerar nova chave privada"**
4. Confirme e baixe o arquivo JSON

**Abra o arquivo JSON e copie:**
- `project_id` → Firebase Project ID
- `client_email` → Firebase Client Email
- `private_key` → Firebase Private Key (incluindo BEGIN e END)

**Configure no painel admin** em Settings → Firebase Configuration

---

#### **Passo 5: Configurar Android**

**5.1 - Adicionar google-services.json:**
```
Copie o arquivo para: android/app/google-services.json
```

**5.2 - Editar `android/build.gradle`:**
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'  // ← Adicione
    }
}
```

**5.3 - Editar `android/app/build.gradle` (no FINAL):**
```gradle
apply plugin: 'com.google.gms.google-services'  // ← Adicione
```

**5.4 - Permissões em `android/app/src/main/AndroidManifest.xml`:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <application ...>
        <!-- Código existente -->
    </application>
</manifest>
```

---

#### **Passo 6: Configurar iOS**

**6.1 - Adicionar GoogleService-Info.plist:**
1. Abra no Xcode: `ios/Runner.xcworkspace`
2. Clique direito na pasta **Runner**
3. **Add Files to "Runner"...**
4. Selecione o arquivo `GoogleService-Info.plist`
5. Marque **"Copy items if needed"**
6. Clique em **"Add"**

**6.2 - Editar `ios/Runner/Info.plist`:**
```xml
<dict>
    <!-- Código existente... -->

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Precisamos da sua localização para encontrar entregas próximas</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Precisamos da sua localização em segundo plano para receber entregas</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Precisamos da sua localização para encontrar entregas próximas</string>
</dict>
```

**6.3 - Habilitar Capabilities no Xcode:**
1. Selecione o projeto **Runner**
2. Aba **"Signing & Capabilities"**
3. Clique em **"+ Capability"**
4. Adicione **"Push Notifications"**
5. Adicione **"Background Modes"**
6. Marque **"Remote notifications"**

---

### Configurar FCM no App Flutter

**1. Adicionar dependências no `pubspec.yaml`:**
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

**2. Inicializar Firebase:**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configurar FCM
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicitar permissão para notificações
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    sound: true,
    badge: true,
  );

  print('Permissão concedida: ${settings.authorizationStatus}');

  runApp(MyApp());
}
```

**3. Obter e enviar FCM Token:**
```dart
Future<String?> getFCMToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');
  return fcmToken;
}

// Enviar token no login
final fcmToken = await getFCMToken();
await dio.post('/api/v1/driver/login', data: {
  'mobile': mobile,
  'password': password,
  'deviceToken': fcmToken, // ← Token FCM
  'loginBy': Platform.isAndroid ? 'android' : 'ios',
});
```

**4. Escutar notificações:**
```dart
class FCMService {
  static Future<void> initialize() async {
    // Quando app está em foreground (primeiro plano)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificação recebida: ${message.notification?.title}');
      print('Dados: ${message.data}');

      // Se for notificação de nova entrega
      if (message.data['type'] == 'new_delivery') {
        // Timeout de aceitação em segundos
        final acceptanceTimeout = int.tryParse(message.data['acceptanceTimeout'] ?? '30') ?? 30;

        showNewDeliveryDialog(
          deliveryId: message.data['deliveryId'],
          requestNumber: message.data['requestNumber'],
          pickupAddress: message.data['pickupAddress'],
          dropoffAddress: message.data['dropoffAddress'],
          estimatedAmount: message.data['estimatedAmount'],
          distance: message.data['distance'],
          time: message.data['time'],
          acceptanceTimeout: acceptanceTimeout,
        );
      }
    });

    // Quando app está em background e usuário toca na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificação aberta: ${message.notification?.title}');

      // Navegar para tela apropriada
      if (message.data['type'] == 'new_delivery') {
        Navigator.pushNamed(context, '/available-deliveries');
      }
    });

    // Verificar se app foi aberto por notificação (quando estava fechado)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      // App foi aberto por notificação
      handleInitialMessage(initialMessage);
    }
  }
}
```

**5. Dialog de Nova Entrega com Countdown Timer:**
```dart
void showNewDeliveryDialog({
  required String deliveryId,
  required String requestNumber,
  required String pickupAddress,
  required String dropoffAddress,
  required String estimatedAmount,
  required String distance,
  required String time,
  required int acceptanceTimeout, // Tempo em segundos
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => NewDeliveryDialog(
      deliveryId: deliveryId,
      requestNumber: requestNumber,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      estimatedAmount: estimatedAmount,
      distance: distance,
      time: time,
      acceptanceTimeout: acceptanceTimeout,
    ),
  );
}

// Widget StatefulWidget para o Dialog com Timer
class NewDeliveryDialog extends StatefulWidget {
  final String deliveryId;
  final String requestNumber;
  final String pickupAddress;
  final String dropoffAddress;
  final String estimatedAmount;
  final String distance;
  final String time;
  final int acceptanceTimeout;

  const NewDeliveryDialog({
    required this.deliveryId,
    required this.requestNumber,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedAmount,
    required this.distance,
    required this.time,
    required this.acceptanceTimeout,
  });

  @override
  _NewDeliveryDialogState createState() => _NewDeliveryDialogState();
}

class _NewDeliveryDialogState extends State<NewDeliveryDialog> {
  late int remainingSeconds;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.acceptanceTimeout;
    startCountdown();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          timer.cancel();
          // Tempo esgotado, fechar dialog automaticamente
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(child: Text('Nova Entrega!')),
          // Countdown timer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: remainingSeconds <= 10 ? Colors.red : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$remainingSeconds s',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pedido: ${widget.requestNumber}',
               style: TextStyle(fontWeight: FontWeight.bold)),
          Divider(),
          Text('📍 Retirada:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.pickupAddress),
          SizedBox(height: 10),
          Text('📍 Entrega:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.dropoffAddress),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distância: ${widget.distance} km'),
              Text('Tempo: ${widget.time} min'),
            ],
          ),
          SizedBox(height: 10),
          Text('💰 Valor: R\$ ${widget.estimatedAmount}',
               style: TextStyle(
                 color: Colors.green,
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
               )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: remainingSeconds > 0 ? () async {
            countdownTimer?.cancel();
            await rejectDelivery(widget.deliveryId);
            Navigator.pop(context);
          } : null,
          child: Text('Rejeitar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: remainingSeconds > 0 ? () async {
            countdownTimer?.cancel();
            final accepted = await acceptDelivery(widget.deliveryId);
            if (accepted) {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/delivery-in-progress');
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text('Aceitar'),
        ),
      ],
    );
  }
}
```

---

## 📱 Fluxo Completo de Entrega no App

### Como Funciona o Raio de Pesquisa

```
1. MOTORISTA FICA ONLINE
   └─> POST /api/v1/driver/online-offline (availability: 1)
   └─> App inicia timer para atualizar localização

2. ATUALIZAÇÃO CONSTANTE DE LOCALIZAÇÃO
   └─> A cada 10 segundos: POST /api/v1/driver/location
   └─> Envia latitude e longitude atuais
   └─> Backend armazena no banco de dados

3. EMPRESA CRIA NOVA ENTREGA
   └─> Sistema calcula distância de cada motorista ao ponto de retirada
   └─> Filtra apenas motoristas dentro do raio configurado
   └─> Exemplo: Raio = 10km
       - Motorista A: 5km do pickup → ✅ Recebe notificação
       - Motorista B: 15km do pickup → ❌ Não recebe notificação

4. NOTIFICAÇÃO ENVIADA
   └─> Apenas motoristas dentro do raio recebem
   └─> Dialog abre com countdown timer (ex: 30 segundos)
   └─> Motorista tem tempo limitado para aceitar
```

### Ciclo de Vida de uma Entrega

```
1. MOTORISTA ONLINE
   └─> Aguardando entregas dentro do raio de pesquisa
   └─> Atualizando localização a cada 10s via POST /location

2. NOVA ENTREGA CRIADA
   └─> Push notification recebida
   └─> Dialog mostrando detalhes
   └─> Motorista decide: Aceitar ou Rejeitar

3. SE ACEITAR
   └─> POST /api/v1/driver/deliveries/:id/accept
   └─> Navegar para tela de entrega em andamento
   └─> Mostrar rota no mapa (pickup → dropoff)

4. CHEGOU NO LOCAL DE RETIRADA
   └─> Botão "Cheguei" disponível
   └─> POST /api/v1/driver/deliveries/:id/arrived-pickup
   └─> Status: "Aguardando retirada do pedido"

5. RETIROU O PEDIDO
   └─> Botão "Retirei o pedido" disponível
   └─> POST /api/v1/driver/deliveries/:id/picked-up
   └─> Status: "Indo para entrega"
   └─> Mostrar rota até destino final

6. CHEGOU NO DESTINO
   └─> Botão "Entreguei" disponível
   └─> POST /api/v1/driver/deliveries/:id/delivered
   └─> Status: "Pedido entregue"

7. FINALIZAR ENTREGA
   └─> Botão "Concluir entrega" disponível
   └─> POST /api/v1/driver/deliveries/:id/complete
   └─> Mostrar resumo (distância, tempo, valor)
   └─> Voltar para tela de entregas disponíveis
```

---

## Próximos Passos

1. ✅ Autenticação e registro implementados
2. ✅ Endpoints de entregas (aceitar, rejeitar, status)
3. ✅ Sistema de notificações push (FCM)
4. 🚧 Endpoints de documentos (upload, status)
5. 🚧 Endpoints de ganhos e histórico
6. 🚧 Chat com empresa/admin

---

## 🔍 Verificação e Troubleshooting

### ✅ Checklist de Configuração

**Firebase:**
- [ ] Projeto Firebase criado
- [ ] App Android registrado
- [ ] App iOS registrado
- [ ] `google-services.json` em `android/app/`
- [ ] `GoogleService-Info.plist` adicionado via Xcode
- [ ] Plugin google-services adicionado no build.gradle
- [ ] Permissões configuradas (Android e iOS)
- [ ] Capabilities habilitadas no Xcode
- [ ] Credenciais configuradas no painel admin

**App Flutter:**
- [ ] Dependências firebase instaladas
- [ ] Firebase inicializado no main.dart
- [ ] FCM Token obtido e impresso no console
- [ ] Token enviado no endpoint de login
- [ ] Listeners de notificação configurados
- [ ] Dialog de nova entrega implementado

**Funcionalidades:**
- [ ] Login funcionando
- [ ] Token FCM sendo enviado
- [ ] Toggle online/offline funcionando
- [ ] Atualização de localização a cada 10s
- [ ] Notificações sendo recebidas
- [ ] Dialog abrindo com countdown
- [ ] Aceitar/rejeitar entrega funcionando
- [ ] Atualizações de status funcionando

---

### 🐛 Problemas Comuns

**❌ "Firebase not initialized"**
```dart
// Solução: Adicione no main.dart ANTES de runApp()
await Firebase.initializeApp();
```

**❌ "google-services.json not found"**
```bash
# Solução:
# 1. Verifique se está em: android/app/google-services.json
# 2. Execute:
flutter clean
flutter pub get
```

**❌ "FCM Token is null"**
```dart
// Solução: Verifique permissões
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  sound: true,
  badge: true,
);
print('Status: ${settings.authorizationStatus}');
```

**❌ "Notificações não chegam"**
- Verifique se o token foi enviado no login
- Confirme que está online (`available = true`)
- Verifique se está atualizando localização
- Confirme se está dentro do raio de pesquisa
- Teste com notificação manual do Firebase Console

**❌ "Location permission denied"**
```dart
// Solução: Solicite permissão explicitamente
LocationPermission permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied) {
  // Mostrar dialog explicando porque precisa
}
```

**❌ "Background location not working (iOS)"**
- Verifique Info.plist (todas as 3 chaves de localização)
- Habilite Background Modes no Xcode
- Marque "Location updates" em Background Modes

---

## 📊 Logs Importantes

### No App Flutter

**Logs esperados ao iniciar:**
```
✓ Firebase initialized
✓ FCM Token: dXXXXXXXXXXXXXXX...
✓ Permissão concedida: AuthorizationStatus.authorized
```

**Logs ao fazer login:**
```
✓ Login realizado com sucesso!
✓ Token FCM enviado ao servidor
```

**Logs ao receber notificação:**
```
🔔 Notificação recebida!
Título: Nova Entrega Disponível!
Dados: {type: new_delivery, deliveryId: xxx, ...}
```

**Logs de localização:**
```
📍 Localização atualizada: -23.5505, -46.6333
```

### No Backend (Servidor)

**Logs esperados:**
```
✓ Firebase Admin SDK inicializado com sucesso
✓ 3 de 5 motoristas estão dentro do raio de 10 km
✓ Notificação enviada para 3 motoristas dentro do raio
✓ 3 notificações enviadas de 3
```

---

## 🎯 Endpoints Resumidos

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/driver/register` | Registrar novo motorista |
| POST | `/api/v1/driver/login` | Fazer login e enviar FCM token |
| POST | `/api/v1/driver/logout` | Fazer logout |
| GET | `/api/v1/driver` | Obter dados do motorista |
| POST | `/api/v1/driver/profile` | Atualizar perfil |
| POST | `/api/v1/driver/location` | Atualizar localização (a cada 10s) |
| POST | `/api/v1/driver/online-offline` | Ficar online/offline |
| GET | `/api/v1/driver/deliveries/available` | Listar entregas disponíveis |
| GET | `/api/v1/driver/deliveries/current` | Obter entrega atual |
| POST | `/api/v1/driver/deliveries/:id/accept` | Aceitar entrega |
| POST | `/api/v1/driver/deliveries/:id/reject` | Rejeitar entrega |
| POST | `/api/v1/driver/deliveries/:id/arrived-pickup` | Chegou para retirada |
| POST | `/api/v1/driver/deliveries/:id/picked-up` | Retirou pedido |
| POST | `/api/v1/driver/deliveries/:id/delivered` | Entregou pedido |
| POST | `/api/v1/driver/deliveries/:id/complete` | Finalizar entrega |

---

## 📱 Fluxo de Integração Sugerido

**Fase 1 - Setup Básico:**
1. ✅ Criar projeto Flutter
2. ✅ Configurar Firebase (Android + iOS)
3. ✅ Adicionar dependências
4. ✅ Testar FCM Token

**Fase 2 - Autenticação:**
1. ✅ Implementar tela de login
2. ✅ Integrar com API de login
3. ✅ Enviar FCM token no login
4. ✅ Salvar sessão localmente

**Fase 3 - Localização:**
1. ✅ Solicitar permissões de localização
2. ✅ Implementar LocationService
3. ✅ Atualizar localização a cada 10s quando online
4. ✅ Testar se localização está sendo enviada

**Fase 4 - Notificações:**
1. ✅ Configurar listeners FCM
2. ✅ Implementar dialog de nova entrega
3. ✅ Adicionar countdown timer
4. ✅ Testar notificações via Firebase Console

**Fase 5 - Entregas:**
1. ✅ Implementar tela de entregas disponíveis
2. ✅ Implementar aceitar/rejeitar
3. ✅ Implementar tela de entrega em andamento
4. ✅ Implementar botões de status
5. ✅ Testar fluxo completo

---

## 🔗 Links Úteis

- **Firebase Console**: https://console.firebase.google.com/
- **Flutter Firebase**: https://firebase.flutter.dev/
- **FCM Documentation**: https://firebase.google.com/docs/cloud-messaging
- **Geolocator Plugin**: https://pub.dev/packages/geolocator
- **Dio HTTP Client**: https://pub.dev/packages/dio

---

## Notas Importantes

1. **Cookies**: Certifique-se de que o Dio está configurado para manter cookies de sessão
2. **HTTPS**: Em produção, sempre use HTTPS
3. **Timeout**: Configure timeouts adequados (30s para requisições normais)
4. **Retry**: Implemente retry logic para falhas de rede
5. **Localização**: Sempre pedir permissão antes de acessar GPS
6. **Background**: Considerar usar background services para atualização de localização
7. **Bateria**: Use `LocationAccuracy.balanced` para economizar bateria em produção
8. **Raio de pesquisa**: Motoristas só recebem notificações dentro do raio configurado
9. **Timeout de aceitação**: Dialog fecha automaticamente após o tempo configurado
10. **Logs**: Sempre monitore os logs para debugar problemas

---

## 📞 Suporte

Para dúvidas ou problemas:
- Consulte a seção de **Troubleshooting** acima
- Verifique os **logs** do app e do servidor
- Revise o **checklist de configuração**
- Consulte `SISTEMA_NOTIFICACOES_ENTREGAS.md` para detalhes do sistema de notificações
