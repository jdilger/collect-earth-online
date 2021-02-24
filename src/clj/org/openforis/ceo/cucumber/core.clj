(ns org.openforis.ceo.cucumber.core
  (:require [clojure.string :as s]
            [clojure.tools.cli  :refer [parse-opts]]
            [org.openforis.ceo.cucumber.runner :as r]))


(def ^:private valid-options
  {:systems #{"Windows" "OS X" "android" "ios"}
   :browsers #{"android" "chrome" "edge" "firefox" "ie" "ipad" "iphone" "opera" "safari"}})

(def cli-options
  [["-b" "--browser BROWSER" "Browser to test, default 'chrome'"
    :id :browser
    :default "chrome"
    :parse-fn #(s/lower-case %)
    :validate [#(contains? (:browsers valid-options) %) (str "Must be one of: " (:browsers valid-options))]]
   ["-r" "--remote" "Run using a remote driver"]
   [nil "--browser-version BROWSER VERSION" "Browser version to test in Remote Driver (-r), defaults to '88.0'"
    :id :browser-version
    :default "88.0"
    :validate [string? "Must be a string"]]
   ["-s" "--system OPERATING SYSTEM" "System to use in Remote Driver (-r), defaults to 'windows'"
    :id :system
    :default "Windows"
    :validate [#(contains? (:systems valid-options) %) (str "Must be one of: " (:systems valid-options))]]
   [nil "--system-version SYSTEM VERSION" "System Version to use in Remote Driver (-r), defaults to 10"
    :id :system-version
    :default "10"
    :validate [#(string? %) "Must be a string"]]
   ["-t" "--test-name TEST NAME" "Browserstack test name to use in Remote Driver (-r)"
    :id :test-name
    :validate [#(string? %) "Must be a string"]]
   ["-u" "--username USERNAME" "Browserstack Username to use in Remote Driver (-r), defaults to environment variable 'BS_USERNAME'"
    :id :username
    :parse-fn #(or % (System/getenv "BS_USERNAME"))
    :validate [#(string? %) "Must be a string"]]
   ["-p" "--api-key API KEY" "Browserstack API Key to use in Remote Driver (-r), defaults to environment variable 'BS_API_KEY'"
    :id :api-key
    :parse-fn #(or % (System/getenv "BS_API_KEY"))
    :validate [#(string? %) "Must be a string"]]
   ["-o" "--output-dir DIR" "Output directory for log files. When a directory is not provided, output will be to stdout."
    :id :output
    :default ""]
   ["-h" "--help"]])

(defn usage [options-summary]
  (->> ["Runs automated BDD-style tests in the browser"
        ""
        "Usage: clj -M:cucumber [options]"
        ""
        "Options:"
        options-summary] (s/join \newline)))

(defn error-msg [errors]
  (str "The following errors occured while parsing your command:\n\n"
       (s/join \newline errors)))

(defn validate-args [args]
  (let [{:keys [options summary errors]} (parse-opts args cli-options)]
    (cond
      (:help options) {:exit-message (usage summary) :ok? true}
      errors {:exit-message (error-msg errors)}
      (< 0 (count options)) {:options options}
      :else {:exit-message (usage summary)})))

(defn exit [status msg]
  (println msg)
  (System/exit status))

(defn start-tests [opts]
  (r/run-cucumber-tests opts))

(defn -main [& args]
  (let [{:keys [options exit-message ok?]} (validate-args args)]
    (if exit-message
      (exit (if ok? 0 1) exit-message)
      (start-tests options))))
