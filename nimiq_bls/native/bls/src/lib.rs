use nimiq_bls::{CompressedPublicKey, PublicKey, SecretKey};
use nimiq_serde::{Deserialize, Serialize};
use nimiq_utils::key_rng::SecureGenerate;
use rustler::{types::Binary, Env, OwnedBinary, Term};

type SecretKeyIn<'a> = Binary<'a>;
type PublicKeyIn<'a> = Binary<'a>;
type SignatureIn<'a> = Binary<'a>;

type SecretKeyOut<'a> = Term<'a>;
type PublicKeyOut<'a> = Term<'a>;
type SignatureOut<'a> = Term<'a>;

#[rustler::nif]
pub fn generate_secret_key(env: Env) -> SecretKeyOut {
    let secret = SecretKey::generate_default_csprng();

    let bytes = secret.serialize_to_vec();
    let mut bin = OwnedBinary::new(bytes.len()).unwrap();
    let _ = bin.as_mut_slice().copy_from_slice(&bytes);
    bin.release(env).to_term(env)
}

#[rustler::nif]
pub fn secret_key_from_bytes<'a>(env: Env<'a>, bytes: Binary) -> Result<SecretKeyOut<'a>, String> {
    let secret = SecretKey::deserialize_from_vec(&bytes).map_err(|e| e.to_string())?;

    let bytes = secret.serialize_to_vec();
    let mut bin = OwnedBinary::new(bytes.len()).unwrap();
    let _ = bin.as_mut_slice().copy_from_slice(&bytes);
    Ok(bin.release(env).to_term(env))
}

#[rustler::nif]
pub fn secret_key_to_bytes<'a>(env: Env<'a>, secret_key: SecretKeyIn) -> Term<'a> {
    secret_key.to_term(env)
}

#[rustler::nif]
pub fn derive_public_key<'a>(env: Env<'a>, secret_key: SecretKeyIn) -> PublicKeyOut<'a> {
    let secret = SecretKey::deserialize_from_vec(&secret_key).unwrap();
    let public = PublicKey::from_secret(&secret).compress();

    let bytes = public.serialize_to_vec();
    let mut bin = OwnedBinary::new(bytes.len()).unwrap();
    let _ = bin.as_mut_slice().copy_from_slice(&bytes);
    bin.release(env).to_term(env)
}

#[rustler::nif]
pub fn public_key_from_bytes<'a>(env: Env<'a>, bytes: Binary) -> Result<Term<'a>, String> {
    let public = CompressedPublicKey::deserialize_from_vec(&bytes).map_err(|e| e.to_string())?;

    let bytes = public.serialize_to_vec();
    let mut bin = OwnedBinary::new(bytes.len()).unwrap();
    let _ = bin.as_mut_slice().copy_from_slice(&bytes);
    Ok(bin.release(env).to_term(env))
}

#[rustler::nif]
pub fn public_key_to_bytes<'a>(env: Env<'a>, public_key: PublicKeyIn) -> Term<'a> {
    public_key.to_term(env)
}

#[rustler::nif]
pub fn create_proof_of_knowledge<'a>(
    env: Env<'a>,
    secret_key: SecretKeyIn,
    public_key: PublicKeyIn,
) -> SignatureOut<'a> {
    let secret = SecretKey::deserialize_from_vec(&secret_key).unwrap();
    let public = CompressedPublicKey::deserialize_from_vec(&public_key)
        .unwrap()
        .uncompress()
        .unwrap();

    let signature = secret.sign(&public).compress();

    let bytes = signature.serialize_to_vec();
    let mut bin = OwnedBinary::new(bytes.len()).unwrap();
    let _ = bin.as_mut_slice().copy_from_slice(&bytes);
    bin.release(env).to_term(env)
}

#[rustler::nif]
pub fn signature_to_bytes<'a>(env: Env<'a>, signature: SignatureIn) -> Term<'a> {
    signature.to_term(env)
}

rustler::init!("bls");
