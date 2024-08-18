pub type PublicKey

pub type SecretKey

pub type Signature

@external(erlang, "bls", "generate_secret_key")
pub fn generate_secret_key() -> SecretKey

@external(erlang, "bls", "secret_key_from_bytes")
pub fn secret_key_from_bytes(bytes: BitArray) -> Result(SecretKey, String)

@external(erlang, "bls", "secret_key_to_bytes")
pub fn secret_key_to_bytes(secret_key: SecretKey) -> BitArray

@external(erlang, "bls", "derive_public_key")
pub fn derive_public_key(secret_key: SecretKey) -> PublicKey

@external(erlang, "bls", "public_key_from_bytes")
pub fn public_key_from_bytes(bytes: BitArray) -> Result(PublicKey, String)

@external(erlang, "bls", "public_key_to_bytes")
pub fn public_key_to_bytes(public_key: PublicKey) -> BitArray

@external(erlang, "bls", "create_proof_of_knowledge")
pub fn create_proof_of_knowledge(
  secret_key: SecretKey,
  public_key: PublicKey,
) -> Signature

@external(erlang, "bls", "signature_to_bytes")
pub fn signature_to_bytes(signature: Signature) -> BitArray
