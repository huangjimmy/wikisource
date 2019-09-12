var path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
var CopyWebpackPlugin = require('copy-webpack-plugin')
var webpack = require('webpack')
var env = process.env.MIX_ENV || 'dev'
var isProduction = (env === 'prod')

module.exports = {
  entry: {
    'app': ['./js/app.js', './css/app.css', './css/phoenix.css']
  },
  output: {
    path: path.resolve(__dirname, '../priv/static/'),
    filename: 'js/[name].js'
  },
  devtool: 'source-map',
  resolve: {
    extensions: ['.js', '.jsx']
  },
  module: {
    rules: [{
      test: /\.(css|scss)$/,
      use: [
        MiniCssExtractPlugin.loader, 
        {
          loader: 'css-loader', // translates CSS into CommonJS modules
        },
        {
          loader: 'sass-loader' // compiles Sass to CSS
        }],
    }, 
    /*{
      test: /\.(css)$/,
      use: [
        MiniCssExtractPlugin.loader, 
        {
          loader: 'css-loader', // inject CSS to page
        }],
    },*/
    {
      test: /\.(js|jsx)$/,
      include: /js/,
      use: [
        { loader: 'babel-loader' }
      ]
    },
    {
      test   : /\.(png|jpg)$/,
      loader : 'file-loader'
    }, 
    {
        test   : /\.(ttf|eot|svg|woff(2)?)(\?[a-z0-9=&.]+)?$/,
        loader : 'file-loader'
    }
  ]
  },
  plugins: [
    new CopyWebpackPlugin([{ from: './static' }]),
    new MiniCssExtractPlugin({ filename: './css/app.css' }),
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery",
      Popper: ['popper.js', 'default']
    })
  ]
}