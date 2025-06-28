# 🎩 Austro Hats - E-commerce Web App

> Sistema de comercio electrónico para sombreros artesanales con autenticación QR

[![Live Demo](https://img.shields.io/badge/🌐_Live_Demo-Visit_Site-blue?style=for-the-badge)](https://proyecto-final-18a2c.web.app/)

## ✨ Características principales

- 🛒 **Carrito persistente** - Tu carrito se guarda automáticamente
- 🔐 **Autenticación segura** - Sistema de login con Firebase Auth
- 📱 **QR de autenticidad** - Verificación de productos genuinos
- 🎨 **Responsive design** - Funciona en móvil, tablet y desktop
- ⚡ **Tiempo real** - Sincronización instantánea con Firebase
- 👥 **Multi-usuario** - Sistema de roles (admin/usuario)

## 🛠️ Tecnologías

- **Flutter Web** - Framework de desarrollo
- **Firebase** - Backend completo (Auth, Firestore, Hosting)
- **Provider** - Gestión de estado reactivo
- **QR Scanner** - Verificación de autenticidad

## 🚀 Demo en vivo

**Web App:** [https://proyecto-final-18a2c.web.app/](https://proyecto-final-18a2c.web.app/)

### Credenciales de prueba:
- **Usuario:** `demo@example.com` | **Contraseña:** `123456`
- **Admin:** `administrador@gmail.com` | **Contraseña:** `admin123`

## 📱 Funcionalidades

| Característica | Usuario | Admin |
|----------------|---------|-------|
| Ver productos | ✅ | ✅ |
| Agregar al carrito | ✅ | ✅ |
| Carrito persistente | ✅ | ✅ |
| Generar QR productos | ❌ | ✅ |
| Verificar QR | ✅ | ✅ |

## 🏃‍♂️ Instalación local

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/proyecto_final_qr_scanner.git

# Instalar dependencias
flutter pub get

# Configurar Firebase
# 1. Crear proyecto en Firebase Console
# 2. Activar Authentication y Firestore
# 3. Descargar google-services.json

# Ejecutar en modo web
flutter run -d chrome
```

## 📂 Estructura del proyecto

```
lib/
├── models/          # Entidades de datos
├── services/        # Firebase y lógica de negocio
├── screens/         # Pantallas principales
├── widgets/         # Componentes reutilizables
└── main.dart        # Punto de entrada
```

## 🔒 Seguridad

- ✅ Autenticación obligatoria para acceso a datos
- ✅ Reglas de Firestore restrictivas
- ✅ Validación en cliente y servidor
- ✅ Sistema de roles implementado

## 📄 Licencia

Este proyecto fue desarrollado como Proyecto Final de Ciclo (PFC) para Desarrollo de Aplicaciones Multiplataforma (DAM).

---

**Desarrollado con ❤️ usando Flutter y Firebase**