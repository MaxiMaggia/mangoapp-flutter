/// Estado logico de una entidad en Firestore.
///
/// Usamos soft delete: nada se borra fisicamente. Si en el futuro hace
/// falta `archived` u otro estado, se agrega aca.
enum EntityStatus { available, deleted }
