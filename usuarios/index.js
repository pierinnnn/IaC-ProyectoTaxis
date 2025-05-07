const { Client } = require('pg');

exports.handler = async (event) => {
  const { id, nombre, correo, contraseña } = JSON.parse(event.body);

  // Validar si faltan datos
  if (!nombre || !correo || !contraseña) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'Faltan datos obligatorios.' })
    };
  }

  // Conexión a la base de datos
  const client = new Client({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: 5432,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();

    // Consulta para insertar los datos
    const query = 'INSERT INTO usuarios (id, nombre, correo, contraseña) VALUES ($1, $2, $3, $4)'; //Asignacion y orden de las columnas
    await client.query(query, [id, nombre, correo, contraseña]);

    await client.end();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Datos insertados correctamente.' })
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Hubo un error al insertar los datos.', error: error.message })
    };
  }
};