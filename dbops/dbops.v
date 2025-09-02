module dbops

// import db.pg
import dotenv

pub const connection_details = ".vivadb/.env"

pub fn connect_db() {
	dets := dotenv.load_dotenv(connection_details) or {panic("no .env")}
	println(dets)
}