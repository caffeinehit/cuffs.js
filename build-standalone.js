// Build cuffs without require.js dependency
({
  baseUrl: "./lib",
  modules: [
    {name: 'cuffs/main'}    
  ],
  out: "cuffs.standalone.min.js"
})
