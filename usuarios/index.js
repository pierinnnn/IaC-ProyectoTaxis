const { Client } = require('pg');

exports.handler = async (event) => {
  console.log(event.requestContext)
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
  };

  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ message: "CORS preflight passed" }),
    };
  }

  const { id, nombre, correo, contraseña } = JSON.parse(event.body || "{}");

  if (!nombre || !correo || !contraseña) {
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({ message: 'Faltan datos obligatorios.' })
    };
  }

  const client = new Client({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: 5432,
    ssl: { rejectUnauthorized: false }
  });

  const group = event.requestContext.authorizer.claims["cognito:groups"];

  if (group === "admin") {
    // lógica admin
  } else if (group === "user") {
    // lógica user
  } else {
    return {
      statusCode: 403,
      headers,
      body: JSON.stringify({ message: "No autorizado" }),
    };
  }


  try {
    await client.connect();

    const query = 'INSERT INTO usuarios (id, nombre, correo, contraseña) VALUES ($1, $2, $3, $4)';
    await client.query(query, [id, nombre, correo, contraseña]);

    await client.end();

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ message: 'Datos insertados correctamente.' }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ message: 'Hubo un error al insertar los datos.', error: error.message })
    };
  }
};
