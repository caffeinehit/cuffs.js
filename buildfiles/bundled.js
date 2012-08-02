// Build Cuffs bundled up with require.js
({
  baseUrl: "../lib",
  modules: [
    {name: 'cuffs/cuffs',
    include: ['requirejs/require.min']}    
  ],
  out: "../cuffs.min.js"
})
